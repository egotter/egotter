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
    if CreateFollowLimitation.remaining_count(current_user) <= 0
      render json: RateLimit.new(current_user).to_h, status: :too_many_requests
    end
  end

  def create
    request = FollowRequest.create!(user_id: current_user.id, uid: params[:uid])
    CreateFollowWorker.perform_async(request.id, enqueue_location: controller_name)
    render json: {request_id: request.id}.merge(RateLimit.new(current_user).to_h)
  end

  def show
    render json: {follow: current_user.following_egotter?}
  end

  private

  class RateLimit
    attr_reader :limit, :remaining

    def initialize(user)
      @limit = CreateFollowLimitation.max_count(user)
      @remaining = CreateFollowLimitation.remaining_count(user)
    end

    def to_h
      {limit: limit, remaining: remaining}
    end
  end
end
