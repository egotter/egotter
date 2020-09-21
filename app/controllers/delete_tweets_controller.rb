class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: [:show, :delete]

  def new
  end

  def show
    @request = current_user.delete_tweets_requests.order(created_at: :desc).first
    @processing = @request && @request.processing?

    unless current_user.authorized?
      flash.now[:alert] = unauthorized_message(current_user.screen_name)
    end
  end

  def delete
    if current_user.authorized?
      request = DeleteTweetsRequest.create!(session_id: egotter_visit_id, user_id: current_user.id, tweet: params[:tweet] == 'true')
      jid = DeleteTweetsWorker.perform_async(request.id, user_id: current_user.id)
      render json: {jid: jid}
    else
      render json: {message: unauthorized_message(current_user.screen_name)}, status: :unauthorized
    end
  end
end
