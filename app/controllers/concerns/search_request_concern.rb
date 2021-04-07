require 'active_support/concern'

module SearchRequestConcern
  extend ActiveSupport::Concern
  include ValidationConcern

  included do
    around_action :disable_newrelic_tracer_for_crawlers, only: :show
    before_action(only: :show) { head :forbidden if twitter_dm_crawler? }
    before_action(only: :show) { signed_in_user_authorized? }
    before_action(only: :show) { current_user_has_dm_permission? }
    before_action(only: :show) { current_user_not_blocker? }
    before_action(only: :show) { valid_screen_name? }
    before_action(only: :show) do
      if skip_search_request_check?
        logger.info "Maybe too many retries of #search_request_cache_exists? screen_name=#{params[:screen_name]} elapsed_time=#{params[:elapsed_time]}"
      else
        if check_search_request_cache_controller?
          search_request_cache_exists?(params[:screen_name])
        end
      end
    end
    before_action(only: :show) { @self_search = current_user_search_for_yourself?(params[:screen_name]) }
    before_action(only: :show) { !@self_search && !not_found_screen_name?(params[:screen_name]) && !not_found_user?(params[:screen_name]) }
    before_action(only: :show) { !@self_search && !forbidden_screen_name?(params[:screen_name]) && !forbidden_user?(params[:screen_name]) }

    # Memo: Call the API for both the purpose of converting :screen_name to :uid and
    # confirming the latest account status
    before_action(only: :show) { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }

    before_action(only: :show) { private_mode_specified?(@twitter_user) }
    before_action(only: :show) { search_limitation_soft_limited?(@twitter_user) }
    before_action(only: :show) { !@self_search && !protected_search?(@twitter_user) }
    before_action(only: :show) { !@self_search && !blocked_search?(@twitter_user) }
    before_action(only: :show) { !@self_search && can_search_adult_user?(@twitter_user) }
    before_action(only: :show) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: :show) { twitter_db_user_persisted?(@twitter_user.uid) } # Not redirected
    before_action(only: :show) { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) } # Call after #twitter_user_persisted?

    before_action(only: :show) { set_new_screen_name_if_changed }
  end

  def skip_search_request_check?
    params[:skip_search_request_check] == 'true' || (controller_name == 'close_friends' && twitter_crawler?)
  end

  def check_search_request_cache_controller?
    %w(timelines close_friends unfriends unfollowers mutual_unfriends replying replied).include?(controller_path)
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
