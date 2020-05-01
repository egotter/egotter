# Perform a request and log an error
class StartCreatingTwitterUsersTask

  def initialize
  end

  def start!
    last_request = CreateTwitterUserRequest.order(created_at: :desc).first
    last_request = CreateTwitterUserRequest.new(created_at: 1.second.ago) unless last_request

    user_ids = AccessDay.where('created_at > ?', CreatePeriodicReportRequest::PERIOD_DURATION.ago).select(:user_id).distinct.map(&:user_id)
    requests = []
    User.where(id: user_ids).find_each do |user|
      requests << CreateTwitterUserRequest.new(
          requested_by: 'batch',
          user_id: user.id,
          uid: user.uid
      )
    end
    CreateTwitterUserRequest.import requests, validate: false

    CreateTwitterUserRequest.where('created_at > ?', last_request.created_at).find_each do |request|
      CreateBatchTwitterUserWorker.perform_async(request.id)
    end
  end
end
