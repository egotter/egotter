class SettingsController < ApplicationController
  include JobQueueingConcern

  skip_before_action :current_user_not_blocker?

  before_action { head :forbidden if twitter_dm_crawler? }
  before_action :require_login!
  before_action :enqueue_update_authorized
  before_action :enqueue_update_egotter_friendship

  def index
    @reset_egotter_request = current_user.reset_egotter_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
    @reset_cache_request = current_user.reset_cache_requests.not_finished.where(created_at: 12.hours.ago..Time.zone.now).exists?
  end

  def account
    @create_periodic_tweet_request = CreatePeriodicTweetRequest.find_by(user_id: current_user.id)
  end

  def periodic_report
  end

  def block_report
  end

  def mute_report
  end

  def search_report
  end

  def sneak_search
    @sneak_search_request = SneakSearchRequest.find_by(user_id: current_user.id)
  end

  def private_mode
    @private_mode_setting = PrivateModeSetting.find_by(user_id: current_user.id)
  end

  def order_history
    @orders = current_user.orders.order(created_at: :desc).limit(10)
  end
end
