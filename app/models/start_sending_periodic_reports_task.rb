# Perform a request and log an error
class StartSendingPeriodicReportsTask

  def initialize(user_ids: nil, start_date: nil, end_date: nil, delay: nil, limit: 5000, remind_only: false, send_only_if_changed: false)
    if user_ids.present?
      @user_ids = self.class.reject_stop_requested_user_ids(user_ids)
    end

    @start_date = start_date
    @end_date = end_date
    @delay = delay
    @limit = limit
    @remind_only = remind_only
    @send_only_if_changed = send_only_if_changed
  end

  def start!
    if @remind_only
      start_reminding!
    else
      start_sending!
    end
  end

  def start_sending!
    user_ids = initialize_user_ids
    return if user_ids.empty?

    last_request = CreatePeriodicReportRequest.order(created_at: :desc).first
    last_request = CreatePeriodicReportRequest.new(created_at: 1.second.ago) unless last_request

    sleep 1 # Increase created_at of imported records
    requests = user_ids.map { |user_id| CreatePeriodicReportRequest.new(user_id: user_id, requested_by: 'batch') }
    CreatePeriodicReportRequest.import requests, validate: false

    CreatePeriodicReportRequest.where('created_at > ?', last_request.created_at).find_each do |request|
      next if request.status.present? || request.finished_at.present?

      job_args = [request.id, user_id: request.user_id, create_twitter_user: true, send_only_if_changed: @send_only_if_changed]

      if @delay
        CreatePeriodicReportWorker.perform_in(@delay, *job_args)
      else
        CreatePeriodicReportWorker.perform_async(*job_args)
      end
    end
  end

  def start_reminding!
    user_ids = initialize_remind_only_user_ids
    return if user_ids.empty?

    requests = user_ids.map { |user_id| RemindPeriodicReportRequest.new(user_id: user_id) }
    RemindPeriodicReportRequest.import requests, validate: false

    user_ids.each do |user_id|
      if @delay
        CreatePeriodicReportMessageWorker.perform_in(@delay, user_id, allotted_messages_will_expire: true)
      else
        CreatePeriodicReportMessageWorker.perform_async(user_id, allotted_messages_will_expire: true)
      end
    end
  end

  def initialize_remind_only_user_ids
    if @user_ids.nil?
      user_ids = self.class.allotted_messages_will_expire_user_ids
      @user_ids = user_ids.uniq
      Rails.logger.debug { "#{self.class}##{__method__} user_ids.size=#{@user_ids.size}" }
    end

    @user_ids
  end

  def initialize_user_ids
    if @user_ids.nil?
      user_ids = self.class.dm_received_user_ids
      user_ids += self.class.recent_access_user_ids(@start_date, @end_date).take(@limit)
      user_ids += self.class.new_user_ids(@start_date, @end_date).take(@limit)
      @user_ids = user_ids.uniq
      Rails.logger.debug { "#{self.class}##{__method__} user_ids.size=#{@user_ids.size}" }
    end

    @user_ids
  end

  class << self
    def morning_user_ids
      user_ids = (dm_received_user_ids + new_user_ids(1.day.ago, Time.zone.now)).uniq
      reject_specific_period_stopped_user_ids(user_ids, :morning)
    end

    def afternoon_user_ids
      user_ids = (dm_received_user_ids + new_user_ids(1.day.ago, Time.zone.now)).uniq
      reject_specific_period_stopped_user_ids(user_ids, :afternoon)
    end

    def night_user_ids
      (dm_received_user_ids + new_user_ids(1.day.ago, Time.zone.now)).uniq
    end

    def reject_specific_period_stopped_user_ids(user_ids, period_name)
      user_ids.each_slice(1000).each do |user_ids_array|
        settings = PeriodicReportSetting.where(user_id: user_ids_array).where(period_name => false).select(:id, :user_id)
        user_ids -= settings.map(&:user_id)
      end
      user_ids
    end

    def dm_received_user_ids
      uids = GlobalDirectMessageReceivedFlag.new.to_a.map(&:to_i)
      user_ids = uids.each_slice(1000).map { |uids_array| User.where(authorized: true, uid: uids_array).pluck(:id) }.flatten
      reject_stop_requested_user_ids(user_ids)
    end

    ACCESS_DAYS_START = 12.hours
    ACCESS_DAYS_END = 3.hours

    def recent_access_user_ids(start_date = nil, end_date = nil)
      start_date = ACCESS_DAYS_START.ago unless start_date
      end_date = ACCESS_DAYS_END.ago unless end_date

      # The target is `created_at`, not 'date'
      user_ids = AccessDay.where(created_at: start_date..end_date).select(:user_id).distinct.map(&:user_id)
      user_ids = user_ids.each_slice(1000).map { |ids_array| User.where(authorized: true, id: ids_array).pluck(:id) }.flatten
      reject_stop_requested_user_ids(user_ids)
    end

    NEW_USERS_START = 1.day
    NEW_USERS_END = 1.second

    def new_user_ids(start_date = nil, end_date = nil)
      start_date = NEW_USERS_START.ago unless start_date
      end_date = NEW_USERS_END.ago unless end_date

      user_ids = User.where(created_at: start_date..end_date).where(authorized: true).pluck(:id)
      reject_stop_requested_user_ids(user_ids)
    end

    def reject_stop_requested_user_ids(user_ids)
      StopPeriodicReportRequest.select(:id, :user_id).find_in_batches do |requests|
        user_ids -= requests.map(&:user_id)
      end
      user_ids
    end

    def allotted_messages_will_expire_user_ids(reject_stop_requested: true, reject_remind_requested: true)
      uids = GlobalDirectMessageReceivedFlag.new.to_a.map(&:to_i)
      users = uids.each_slice(1000).map { |uids_array| User.where(authorized: true, uid: uids_array).select(:id, :uid) }.flatten
      users.sort_by! { |user| uids.index(user.uid) }
      user_ids = users.select do |user|
        PeriodicReport.allotted_messages_will_expire_soon?(user) &&
            PeriodicReport.allotted_messages_left?(user)
      end.map(&:id)
      user_ids = reject_stop_requested ? reject_stop_requested_user_ids(user_ids) : user_ids
      reject_remind_requested ? reject_remind_requested_user_ids(user_ids) : user_ids
    end

    def reject_remind_requested_user_ids(user_ids)
      RemindPeriodicReportRequest.select(:id, :user_id).find_in_batches do |requests|
        user_ids -= requests.map(&:user_id)
      end
      user_ids
    end
  end
end
