class FollowsController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :reject_crawler
  before_action :require_login!
  before_action(only: :create) { valid_uid?(params[:uid]) }

  before_action do
    if action_name == 'create'
      create_search_log(uid: params[:uid])
    else
      create_search_log
    end
  end

  before_action only: :create do
    if params[:uid].to_i == User::EGOTTER_UID
      CreateEgotterFollowerWorker.perform_async(current_user.id)
    end
  end

  before_action only: :create do
    unless current_user.create_follow_remaining?
      render json: rate_limit_values(current_user, nil), status: :too_many_requests
    end
  end

  def create
    request = FollowRequest.create!(user_id: current_user.id, uid: params[:uid])
    enqueue_create_follow_job_if_needed(request, enqueue_location: controller_name)
    render json: rate_limit_values(current_user, request)
  end

  def show
    render json: {follow: current_user.following_egotter?}
  end

  private

  def rate_limit_values(user, request)
    {
        request_id: request&.id,
        limit: user.create_follow_limit,
        remaining: user.create_follow_remaining
    }
  end
end
