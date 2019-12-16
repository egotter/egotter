require 'active_support/concern'

module Concerns::SearchRequestConcern
  extend ActiveSupport::Concern
  include Concerns::ValidationConcern

  included do
    before_action(only: %i(show all)) { signed_in_user_authorized? }
    before_action(only: %i(show all)) { enough_permission_level? }
    before_action(only: %i(show all)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
    before_action(only: %i(show all)) { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
    before_action(only: %i(show all)) { search_limitation_soft_limited?(@twitter_user) }
    before_action(only: %i(show all)) { !protected_search?(@twitter_user) && !blocked_search?(@twitter_user) }
    before_action(only: %i(show all)) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: %i(show all)) { twitter_db_user_persisted?(@twitter_user.uid) } # Not redirected
    before_action(only: %i(show all)) { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) } # Call after #twitter_user_persisted?

    before_action(only: %i(show all)) do
      if screen_name_changed?(@twitter_user)
        flash.now[:notice] = screen_name_changed_message(@twitter_user.screen_name)
        @new_screen_name = @twitter_user.screen_name
      end

      @twitter_user = TwitterUser.with_delay.latest_by(uid: @twitter_user.uid)
      @twitter_user.screen_name = @new_screen_name if @new_screen_name
    end

    before_action(only: %i(show all)) do
      push_referer
      create_search_log
    end
  end
end
