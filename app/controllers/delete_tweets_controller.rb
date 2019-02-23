class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: :delete

  def new
    if user_signed_in?
      @delete_tweets_log = DeleteTweetsLog.where(user_id: current_user.id, created_at: 1.hour.ago..Time.zone.now).exists?
    end
  end

  def delete
    jid =
        DeleteTweetsWorker.perform_async(
            session_id: fingerprint,
            user_id: current_user.id
        )
    render json: {jid: jid}
  end
end
