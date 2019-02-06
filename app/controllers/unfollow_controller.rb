class UnfollowController < ApplicationController
  include WorkersHelper

  before_action :reject_crawler
  before_action :require_login!

  before_action {create_search_log(uid: params[:uid])}

  before_action do
    unless current_user.can_create_unfollow?
      render json: {
          can_create_unfollow: false,
          create_unfollow_limit: current_user.create_unfollow_limit,
          create_unfollow_remaining: current_user.create_unfollow_remaining
      }, status: :too_many_requests
    end
  end

  def create
    user = current_user
    request = UnfollowRequest.new(user_id: user.id, uid: params[:uid])
    if request.save
      enqueue_create_unfollow_job_if_needed(user.id)

      render json: {
          unfollow_request_id: request.id,
          global_can_create_unfollow: Concerns::User::FollowAndUnfollow::Util.global_can_create_unfollow?,
          can_create_unfollow: user.can_create_unfollow?,
          create_unfollow_limit: user.create_unfollow_limit,
          create_unfollow_remaining: user.create_unfollow_remaining
      }
    else
      logger.warn "#{controller_name}##{action_name} #{request.errors.full_messages}"
      head :unprocessable_entity
    end
  end
end
