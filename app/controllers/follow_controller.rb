class FollowController < ApplicationController
  include WorkersHelper

  before_action :reject_crawler
  before_action :require_login!

  before_action do
    if action_name == 'create'
      create_search_log(uid: params[:uid])
    else
      create_search_log
    end
  end

  def create
    user = current_user
    request = FollowRequest.new(user_id: user.id, uid: params[:uid])
    if request.save
      enqueue_create_follow_job_if_needed(user.id)

      render json: {
          follow_request_id: request.id,
          can_create_follow: user.can_create_follow?,
          create_follow_limit: user.create_follow_limit
      }
    else
      logger.warn "#{controller_name}##{action_name} #{request.errors.full_messages}"
      head :unprocessable_entity
    end
  end

  def check
    follow = Bot.api_client.twitter.friendship?(current_user.uid.to_i, User::EGOTTER_UID)
    render json: {follow: follow}
  end
end
