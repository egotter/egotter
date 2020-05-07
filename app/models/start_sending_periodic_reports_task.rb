# Perform a request and log an error
class StartSendingPeriodicReportsTask

  ACCESS_DAYS_START = 12.hours
  NEW_USERS_START = 1.day

  def initialize(user_ids: nil, start_date: nil, delay: nil, limit: 5000)
    @delay = delay

    if user_ids.present?
      @user_ids = user_ids
    else
      user_ids = dm_received_user_ids
      user_ids += recent_access_user_ids(start_date).take(limit)
      user_ids += new_user_ids(start_date).take(limit)
      @user_ids = user_ids.uniq
    end

    Rails.logger.debug { "StartSendingPeriodicReportsTask user_ids.size=#{@user_ids.size}" }
  end

  def start!
    last_request = CreatePeriodicReportRequest.order(created_at: :desc).first
    last_request = CreatePeriodicReportRequest.new(created_at: 1.second.ago) unless last_request

    requests = @user_ids.map { |user_id| CreatePeriodicReportRequest.new(user_id: user_id) }
    CreatePeriodicReportRequest.import requests, validate: false

    CreatePeriodicReportRequest.where('created_at > ?', last_request.created_at).find_each do |request|
      args = [request.id, user_id: request.user_id, create_twitter_user: true]

      if @delay
        CreatePeriodicReportWorker.perform_in(@delay, *args)
      else
        CreatePeriodicReportWorker.perform_async(*args)
      end
    end
  end

  def dm_received_user_ids
    uids = GlobalDirectMessageReceivedFlag.new.to_a.map(&:to_i)
    uids.each_slice(1000).map { |uids_array| User.where(authorized: true, uid: uids_array).pluck(:id) }.flatten
  end

  def recent_access_user_ids(start_date)
    start_date = ACCESS_DAYS_START.ago unless start_date
    user_ids = AccessDay.where('created_at > ?', start_date).select(:user_id).distinct.map(&:user_id)
    user_ids.each_slice(1000).map { |ids_array| User.where(authorized: true, id: ids_array).pluck(:id) }.flatten
  end

  def new_user_ids(start_date)
    start_date = NEW_USERS_START.ago unless start_date
    User.where('created_at > ?', start_date).where(authorized: true).pluck(:id)
  end
end
