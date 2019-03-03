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

  before_action do
    unless current_user.can_create_follow?
      render json: {
          create_follow_limit: current_user.create_follow_limit,
          create_follow_remaining: current_user.create_follow_remaining
      }, status: :too_many_requests
    end
  end

  def create
    user = current_user
    request = FollowRequest.new(user_id: user.id, uid: params[:uid])
    if request.save
      enqueue_create_follow_or_unfollow_job_if_needed(request, enqueue_location: 'FollowController')

      render json: {
          follow_request_id: request.id,
          create_follow_limit: user.create_follow_limit,
          create_follow_remaining: user.create_follow_remaining
      }
    else
      logger.warn "#{controller_name}##{action_name} #{request.errors.full_messages}"
      head :unprocessable_entity
    end
  end

  def check
    follow = request_context_client.twitter.friendship?(current_user.uid.to_i, User::EGOTTER_UID)
    render json: {follow: follow}
  rescue Twitter::Error::Forbidden => e
    raise if e.message != 'Could not determine source user.'
    render json: {follow: nil}
  end
end
