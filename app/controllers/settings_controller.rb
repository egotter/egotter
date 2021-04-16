class SettingsController < ApplicationController
  include JobQueueingConcern

  skip_before_action :current_user_not_blocker?

  before_action { head :forbidden if twitter_dm_crawler? }
  before_action :require_login!

  def index
    enqueue_update_authorized
    enqueue_update_egotter_friendship

    @reset_egotter_request = current_user.reset_egotter_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
    @reset_cache_request = current_user.reset_cache_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
    @create_periodic_tweet_request = CreatePeriodicTweetRequest.find_by(user_id: current_user.id)
    @sneak_search_request = SneakSearchRequest.find_by(user_id: current_user.id)
    @private_mode_setting = PrivateModeSetting.find_by(user_id: current_user.id)
  end
end
