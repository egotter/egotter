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
    request = FollowRequest.create!(user_id: current_user.id, uid: params[:uid], requested_by: 'follows#create')
    CreateFollowWorker.perform_async(request.id, enqueue_location: controller_name)
    render json: {request_id: request.id}.merge(RateLimit.new(current_user).to_h)
  end

  def show
    if EgotterFollower.exists?(uid: current_user.uid, updated_at: 5.minutes.ago..Time.zone.now)
      return render json: {follow: true, record_found: true}
    end

    if request_context_client.twitter.friendship?(current_user.uid, User::EGOTTER_UID)
      CreateEgotterFollowerWorker.perform_async(current_user.id)
      render json: {follow: true, record_found: false}
    else
      DeleteEgotterFollowerWorker.perform_async(current_user.id)
      render json: {follow: false, record_found: false}
    end
  rescue => e
    unless AccountStatus.unauthorized?(e)
      logger.warn "#{controller_name}##{action_name} #{e.inspect} #{request.referer}"
    end
    render json: {follow: current_user.following_egotter?, record_found: nil}
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
