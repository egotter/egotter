class SettingsController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :require_login!

  def index
    enqueue_update_authorized
    enqueue_update_egotter_friendship

    @reset_egotter_request = current_user.reset_egotter_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
    @reset_cache_request = current_user.reset_cache_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
  end

  def follow_requests
    @requests = current_user.follow_requests.limit(20)
    @users = TwitterDB::User.where(uid: @requests.map(&:uid)).index_by(&:uid)
  end

  def unfollow_requests
    @requests = current_user.unfollow_requests.limit(20)
    @users = TwitterDB::User.where(uid: @requests.map(&:uid)).index_by(&:uid)
  end
end
