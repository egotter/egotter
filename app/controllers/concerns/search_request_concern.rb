require 'active_support/concern'

module SearchRequestConcern
  extend ActiveSupport::Concern
  include ValidationConcern
  include SearchRequestInstrumentationConcern

  included do
    before_action(only: :show) { head :forbidden if twitter_dm_crawler? }
    before_action(only: :show) { search_request_concern_bm_start }
    before_action(only: :show) { signed_in_user_authorized? }
    before_action(only: :show) { enough_permission_level? }
    before_action(only: :show) { valid_screen_name? }
    before_action(only: :show) { @self_search = user_requested_self_search? }
    before_action(only: :show) { !@self_search && !not_found_screen_name?(params[:screen_name]) && !not_found_user?(params[:screen_name]) }
    before_action(only: :show) { !@self_search && !forbidden_screen_name?(params[:screen_name]) && !forbidden_user?(params[:screen_name]) }
    before_action(only: :show) { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
    before_action(only: :show) { search_limitation_soft_limited?(@twitter_user) }
    before_action(only: :show) { !@self_search && !protected_search?(@twitter_user) }
    before_action(only: :show) { !@self_search && !blocked_search?(@twitter_user) }
    before_action(only: :show) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: :show) { twitter_db_user_persisted?(@twitter_user.uid) } # Not redirected
    before_action(only: :show) { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) } # Call after #twitter_user_persisted?

    before_action(only: :show) { set_new_screen_name_if_changed }
    before_action(only: :show) { search_request_concern_bm_finish }
  end

  def set_new_screen_name_if_changed
    if screen_name_changed?(@twitter_user)
      flash.now[:notice] = screen_name_changed_message(@twitter_user.screen_name)
      @new_screen_name = @twitter_user.screen_name
    end

    @twitter_user = TwitterUser.with_delay.latest_by(uid: @twitter_user.uid)
    @twitter_user.screen_name = @new_screen_name if @new_screen_name
  end
end
