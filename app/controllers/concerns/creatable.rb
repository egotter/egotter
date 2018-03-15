require 'active_support/concern'

module Concerns::Creatable
  extend ActiveSupport::Concern
  include Concerns::Validation

  included do
    before_action :reject_crawler, only: %i(create)
    before_action(only: %i(create)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
    before_action(only: %i(create)) { @twitter_user = build_twitter_user(params[:screen_name]) }
    before_action(only: %i(create)) { !blocked_search?(@twitter_user) }
    before_action(only: %i(create)) { authorized_search?(@twitter_user) }
  end

end
