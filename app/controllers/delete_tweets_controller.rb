class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: :delete

  def new
    if user_signed_in?
      @delete_tweets_request = DeleteTweetsRequest.not_finished(current_user.id).exists?
    end
  end

  def delete
    request = DeleteTweetsRequest.create!(session_id: fingerprint, user_id: current_user.id)
    jid = DeleteTweetsWorker.perform_async(request.id, user_id: current_user.id)
    render json: {jid: jid}
  end
end
