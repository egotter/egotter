# Perform a request and log an error
class StartSendingPeriodicReportsTask

  def initialize(user_ids: nil, start_date: nil)
    if user_ids.present?
      @user_ids = user_ids
    else
      uids = GlobalDirectMessageReceivedFlag.new.to_a.map(&:to_i)
      user_ids = uids.each_slice(1000).map { |uids_array| User.where(authorized: true, uid: uids_array).pluck(:id) }.flatten

      # start_date = CreatePeriodicReportRequest::PERIOD_DURATION.ago unless start_date
      # user_ids += AccessDay.where('created_at > ?', start_date).select(:user_id).distinct.map(&:user_id)

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
      CreatePeriodicReportWorker.perform_async(request.id, user_id: request.user_id, create_twitter_user: true)
    end
  end
end
