require 'active_support/concern'

module Concerns::SearchByUidConcern
  extend ActiveSupport::Concern
  include Concerns::Validation

  included do
    before_action(only: %i(show)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
    before_action(only: %i(show)) { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
    before_action(only: %i(show)) { !blocked_search?(@twitter_user) }
    before_action(only: %i(show)) { authorized_search?(@twitter_user) }
    before_action(only: %i(show)) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: %i(show)) { twitter_db_user_persisted?(@twitter_user.uid) }
    # before_action(only: %i(show)) { too_many_searches?(@tu) }
    # before_action(only: %i(show)) { too_many_requests?(@tu) }

    before_action(only: %i(show))  do
      @twitter_user = TwitterUser.latest_by(uid: @twitter_user.uid)
    end

    before_action(only: %i(show)) do
      push_referer
      create_search_log
    end
  end
end
