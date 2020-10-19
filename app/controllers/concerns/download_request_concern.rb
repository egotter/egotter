require 'active_support/concern'

module DownloadRequestConcern
  extend ActiveSupport::Concern
  include ValidationConcern

  included do
    before_action(only: :download) { head :forbidden if twitter_dm_crawler? }
    before_action(only: :download) { signed_in_user_authorized? }
    before_action(only: :download) { current_user_has_dm_permission? }
    before_action(only: :download) { valid_screen_name? }
    before_action(only: :download) { @self_search = user_requested_self_search? }
    before_action(only: :download) { !@self_search && !not_found_screen_name?(params[:screen_name]) && !not_found_user?(params[:screen_name]) }
    before_action(only: :download) { !@self_search && !forbidden_screen_name?(params[:screen_name]) && !forbidden_user?(params[:screen_name]) }
    before_action(only: :download) { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
    before_action(only: :download) { search_limitation_soft_limited?(@twitter_user) }
    before_action(only: :download) { !@self_search && !protected_search?(@twitter_user) }
    before_action(only: :download) { !@self_search && !blocked_search?(@twitter_user) }
    before_action(only: :download) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: :download) { twitter_db_user_persisted?(@twitter_user.uid) } # Not redirected
    before_action(only: :download) { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) } # Call after #twitter_user_persisted?
  end

  private

  def filename_for_download(twitter_user)
    "#{twitter_user.screen_name}-#{controller_name}.csv"
  end

  def limit_for_download
    user_signed_in? && current_user.has_valid_subscription? ? Order::BASIC_PLAN_USERS_LIMIT : Order::FREE_PLAN_USERS_LIMIT
  end

  def data_for_download(users)
    CsvBuilder.new(users, with_description: user_signed_in? && current_user.has_valid_subscription?).build
  end
end
