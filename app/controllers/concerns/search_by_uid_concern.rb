require 'active_support/concern'

module Concerns::SearchByUidConcern
  extend ActiveSupport::Concern
  include Concerns::ValidationConcern

  included do
    before_action(only: %i(show all)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
    before_action(only: %i(show all)) { @twitter_user = build_twitter_user_by(screen_name: params[:screen_name]) }
    before_action(only: %i(show all)) { !blocked_search?(@twitter_user) }
    before_action(only: %i(show all)) { authorized_search?(@twitter_user) }
    before_action(only: %i(show all)) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: %i(show all)) { twitter_db_user_persisted?(@twitter_user.uid) }
    # before_action(only: %i(show all)) { too_many_searches?(@twitter_user) }
    # before_action(only: %i(show all)) { too_many_requests?(@twitter_user) }

    before_action(only: %i(show all))  do
      @twitter_user = TwitterUser.latest_by(uid: @twitter_user.uid)
    end

    before_action(only: %i(show all)) do
      push_referer
      create_search_log
    end
  end
end
