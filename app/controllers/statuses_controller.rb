require 'open-uri'

class StatusesController < ApplicationController
  include Validation
  include Concerns::Logging
  include StatusesHelper

  before_action { valid_screen_name?(params[:screen_name]) }
  before_action { not_found_screen_name?(params[:screen_name]) }
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

  def oembed
    if @twitter_user.statuses.limit(20).any? { |status| status.tweet_id == params[:status_id].to_i }
      url = "https://twitter.com/#{@twitter_user.screen_name}/status/#{params[:status_id]}"
      render json: open("https://publish.twitter.com/oembed?align=center&url=#{url}").read
    else
      render :bad_request
    end
  end
end
