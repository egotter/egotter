class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: :delete

  def new
    if user_signed_in?
      requests = current_user.delete_tweets_requests
      @logs = requests.any? ? requests.first.logs.take(5) : []
      @processing = requests.where(created_at: 1.hour.ago..Time.zone.now).where.not(finished_at: nil).exists?
    end
  end

  def delete
    request = DeleteTweetsRequest.create!(session_id: fingerprint, user_id: current_user.id)
    jid = DeleteTweetsWorker.perform_async(request.id, user_id: current_user.id)
    render json: {jid: jid}
  end
end
