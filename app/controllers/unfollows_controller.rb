class UnfollowsController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :reject_crawler
  before_action :require_login!
  before_action { valid_uid?(params[:uid]) }

  before_action {create_search_log(uid: params[:uid])}

  before_action do
    if !referer_is_tokimeki_unfollow? && !current_user.create_unfollow_remaining?
      render json: rate_limit_values(current_user, nil), status: :too_many_requests
    end
  end

  def create
    request = UnfollowRequest.create!(user_id: current_user.id, uid: params[:uid])
    CreateUnfollowWorker.perform_async(request.id, enqueue_location: controller_name) unless from_crawler?
    render json: rate_limit_values(current_user, request)
  end

  private

  def rate_limit_values(user, request)
    {
        request_id: request&.id,
        limit: user.create_unfollow_limit,
        remaining: user.create_unfollow_remaining
    }
  end
end
