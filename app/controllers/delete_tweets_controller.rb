class DeleteTweetsController < ApplicationController
  before_action :require_login!, only: [:show, :delete]

  # TODO Rename to #index
  def new
  end

  def show
    if (request = current_user.delete_tweets_requests.order(created_at: :desc).first)
      @processing = request.processing?
      @request = DeleteTweetsRequestDecorator.new(request)
    end

    unless current_user.authorized?
      flash.now[:alert] = unauthorized_message(current_user.screen_name)
    end
  end

  # TODO Move to Api::V1::DeleteTweetsController
  def delete
    if current_user.authorized?
      request = DeleteTweetsRequest.create!(user_id: current_user.id, tweet: params[:tweet] == 'true')
      jid = DeleteTweetsWorker.perform_async(request.id, user_id: current_user.id)

      track_event('Delete tweets', request_id: request.id)
      SendDeleteTweetsStartedWorker.perform_async(request.id, user_id: current_user.id)
      SendDeleteTweetsNotFinishedWorker.perform_in(30.minutes, request.id, user_id: current_user.id)

      render json: {jid: jid}
    else
      render json: {message: unauthorized_message(current_user.screen_name)}, status: :unauthorized
    end
  end
end
