require 'active_support/concern'

module Concerns::Showable
  extend ActiveSupport::Concern
  include SearchesHelper
  include Concerns::Validation

  included do
    before_action(only: %i(show)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
    before_action(only: %i(show)) { @tu = build_twitter_user(params[:screen_name]) }
    before_action(only: %i(show)) { !blocked_search?(@tu) }
    before_action(only: %i(show)) { authorized_search?(@tu) }
    before_action(only: %i(show)) { twitter_user_persisted?(@tu.uid.to_i) }
    before_action(only: %i(show)) { twitter_db_user_persisted?(@tu.uid.to_i) }
    before_action(only: %i(show)) { too_many_searches? }

    before_action(only: %i(show))  do
      @twitter_user = TwitterUser.latest(@tu.uid.to_i)
      remove_instance_variable(:@tu)
    end

    before_action(only: %i(show)) do
      push_referer
      create_search_log
    end
  end

end
