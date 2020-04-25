class UnfollowsController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :reject_crawler
  before_action :require_login!
  before_action { valid_uid?(params[:uid]) }

  before_action { create_search_log(uid: params[:uid]) }

  before_action do
    if !referer_is_tokimeki_unfollow? && CreateUnfollowLimitation.remaining_count(current_user) <= 0
      render json: RateLimit.new(current_user).to_h, status: :too_many_requests
    end
  end

  def create
    request = UnfollowRequest.create!(user_id: current_user.id, uid: params[:uid])
    CreateUnfollowWorker.perform_async(request.id, enqueue_location: controller_name)
    message = t('.success', user: fetch_target_screen_name(params[:uid]))
    render json: {request_id: request.id, message: message}.merge(RateLimit.new(current_user).to_h)
  end

  private

  def fetch_target_screen_name(uid)
    user = TwitterDB::User.find_by(uid: uid)
    user = TwitterUser.latest_by(uid: uid) unless user
    user ? user.screen_name : uid
  end

  class RateLimit
    attr_reader :limit, :remaining

    def initialize(user)
      @limit = CreateUnfollowLimitation.max_count(user)
      @remaining = CreateUnfollowLimitation.remaining_count(user)
    end

    def to_h
      {limit: limit, remaining: remaining}
    end
  end
end
