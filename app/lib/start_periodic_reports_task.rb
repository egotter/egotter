class StartPeriodicReportsTask
  def initialize(period: nil, user_ids: nil, start_date: nil, end_date: nil, limit: 5000)
    @period = period || 'none'

    if user_ids.present?
      @user_ids = self.class.reject_stop_requested_user_ids(user_ids)
    elsif period == 'morning'
      @user_ids = self.class.morning_user_ids
    elsif period == 'afternoon'
      @user_ids = self.class.afternoon_user_ids
    elsif period == 'night'
      @user_ids = self.class.night_user_ids
    end
  end

  def start!
    response = SlackBotClient.channel('cron').post_message("Start sending reports period=#{@period}") rescue {}

    if @user_ids.any?
      requests = create_requests(@user_ids)
      create_jobs(requests)
    end

    SlackBotClient.channel('cron').post_message("Finished user_ids=#{@user_ids.size} period=#{@period}", thread_ts: response['ts']) rescue nil
  end

  def create_requests(user_ids)
    max_id = CreatePeriodicReportRequest.maximum(:id) || 0
    requested_by = "batch(#{@period})"

    requests = user_ids.map { |user_id| CreatePeriodicReportRequest.new(user_id: user_id, requested_by: requested_by) }
    requests.each_slice(1000) do |data|
      CreatePeriodicReportRequest.import data, validate: false
    end

    CreatePeriodicReportRequest.where('id > ?', max_id).where(requested_by: requested_by).select(:id, :user_id)
  end

  def create_jobs(requests)
    seconds = (requests.size / 400 + 1) * 60 # Send 400 messages/minute
    requests.each do |request|
      CreatePeriodicReportWorker.perform_in(rand(seconds), request.id, user_id: request.user_id)
    end
  end

  class << self
    def periodic_base_user_ids
      user_ids = dm_received_user_ids.uniq
      user_ids = reject_banned_user_ids(user_ids)
      user_ids = (user_ids + premium_user_ids).uniq
      reject_stop_requested_user_ids(user_ids)
    end

    def morning_user_ids
      reject_specific_period_stopped_user_ids(periodic_base_user_ids, :morning)
    end

    def afternoon_user_ids
      reject_specific_period_stopped_user_ids(periodic_base_user_ids, :afternoon)
    end

    def night_user_ids
      periodic_base_user_ids
    end

    def reject_specific_period_stopped_user_ids(user_ids, period_name)
      user_ids.each_slice(1000).each do |user_ids_array|
        settings = PeriodicReportSetting.where(user_id: user_ids_array).where(period_name => false).select(:id, :user_id)
        user_ids -= settings.map(&:user_id)
      end
      user_ids
    end

    def dm_received_user_ids
      uids = DirectMessageReceiveLog.received_sender_ids
      uids.each_slice(1000).map { |uids_array| User.authorized.where(uid: uids_array).pluck(:id) }.flatten
    end

    def premium_user_ids
      User.premium.authorized.pluck(:id)
    end

    def reject_stop_requested_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - StopPeriodicReportRequest.where(user_id: ids).pluck(:user_id)
      end.flatten
    end

    def allotted_messages_will_expire_user_ids
      uids = DirectMessageReceiveLog.received_sender_ids
      users = uids.each_slice(1000).map { |uids_array| User.authorized.where(uid: uids_array).select(:id, :uid) }.flatten
      users.sort_by! { |user| uids.index(user.uid) }

      user_ids = users.select do |user|
        PeriodicReport.allotted_messages_will_expire_soon?(user) &&
            DirectMessageSendCounter.count(user.uid) <= 4
      end.map(&:id)

      user_ids = reject_stop_requested_user_ids(user_ids)
      user_ids = reject_remind_requested_user_ids(user_ids)
      user_ids = reject_premium_user_ids(user_ids)
      reject_banned_user_ids(user_ids)
    end

    def reject_remind_requested_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - RemindPeriodicReportRequest.where(user_id: ids).pluck(:user_id)
      end.flatten
    end

    def reject_banned_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - BannedUser.where(user_id: ids).pluck(:user_id)
      end.flatten
    end

    def reject_premium_user_ids(user_ids)
      user_ids - User.premium.pluck(:id)
    end
  end
end
