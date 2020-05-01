# Perform a request and log an error
class StartSendingPeriodicReportsTask

  def initialize
  end

  def start!
    last_request = CreatePeriodicReportRequest.order(created_at: :desc).first
    last_request = CreatePeriodicReportRequest.new(created_at: 1.second.ago) unless last_request

    user_ids = AccessDay.where('created_at > ?', CreatePeriodicReportRequest::PERIOD_DURATION.ago).select(:user_id).distinct.map(&:user_id)
    requests = user_ids.map { |user_id| CreatePeriodicReportRequest.new(user_id: user_id) }
    CreatePeriodicReportRequest.import requests, validate: false

    CreatePeriodicReportRequest.where('created_at > ?', last_request.created_at).find_each do |request|
      CreatePeriodicReportWorker.perform_async(request.id, user_id: request.user_id)
    end
  end
end
