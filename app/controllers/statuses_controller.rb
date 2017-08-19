require 'open-uri'

class StatusesController < ApplicationController
  include Validation
  include StatusesHelper

  before_action { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action { @tu = build_twitter_user(params[:screen_name]) }
  before_action { authorized_search?(@tu) }
  before_action { existing_uid?(@tu.uid.to_i) }
  before_action  do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action(only: %i(show)) do
    push_referer
    create_search_log
  end

  def show
    @statuses = @twitter_user.statuses.limit(20)
  end
end
