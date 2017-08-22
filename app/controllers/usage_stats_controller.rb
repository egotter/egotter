class UsageStatsController < ApplicationController
  include Validation
  include SearchesHelper
  include TweetTextHelper

  before_action { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action(only: %i(show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action(only: %i(show))  do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action do
    push_referer
    create_search_log
  end

  def show
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", screen_name: @twitter_user.screen_name)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name})

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name})

    @stat = UsageStat.find_by(uid: @twitter_user.uid)

    @tweet_text = usage_time_text(@stat&.usage_time, @twitter_user)
  end
end
