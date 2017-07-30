class SearchResultsController < ApplicationController
  include Validation
  include Concerns::Logging
  include PageCachesHelper
  include TweetTextHelper
  include SearchesHelper

  layout false

  before_action :need_login, only: %i(common_friends common_followers)
  before_action(only: Search::MENU) { valid_uid?(params[:uid].to_i) }
  before_action(only: Search::MENU) { existing_uid?(params[:uid].to_i) }
  before_action(only: Search::MENU) { @searched_tw_user = TwitterUser.latest(params[:uid].to_i) }
  before_action(only: Search::MENU) { authorized_search?(@searched_tw_user) }

  %i(new_friends new_followers).each do |menu|
    define_method(menu) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(menu)).items
      render json: {html: render_to_string(template: 'search_results/common', locals: {menu: menu})}, status: 200
    end
  end

  %i(favoriting close_friends).each do |menu|
    define_method(menu) do
      begin
        users = users_for(@searched_tw_user, menu: menu)
        @graph = chart_for(users.size, users.size * 2, menu)
        @tweet_text = close_friends_text(users, @searched_tw_user)
        @user_items = TwitterUsersDecorator.new(users).items
        render json: {html: render_to_string(template: 'search_results/common', locals: {menu: menu})}, status: 200
      rescue => e
        logger.warn "#{self.class}##{menu}: #{e.class} #{e.message} #{current_user_id} #{@searched_tw_user.uid} #{@searched_tw_user.screen_name} #{client.access_token} #{request.device_type} #{request.browser}"
        logger.info e.backtrace.grep_v(/\.bundle/).empty? ? e.backtrace.join("\n") : e.backtrace.grep_v(/\.bundle/).join("\n")
        render nothing: true, status: 500
      end
    end
  end

  # GET /searches/:screen_name/usage_stats
  def usage_stats
    stat = UsageStat.find_by(uid: @searched_tw_user.uid)
    if stat
      @wday           = stat.wday
      @wday_drilldown = stat.wday_drilldown
      @hour           = stat.hour
      @hour_drilldown = stat.hour_drilldown
      @usage_time     = stat.usage_time
      @kind           = stat.breakdown

      hashtags = stat.hashtags
      @cloud = hashtags.map.with_index { |(word, count), i| {text: word, size: count, group: i % 3} }
      @hashtags = hashtags.to_a.take(10).map { |word, count| {name: word, y: count} }
    else
      @wday = @wday_drilldown = @hour = @hour_drilldown = @usage_time = @kind = @cloud = @hashtags = nil
    end

    render json: {html: render_to_string}, status: 200
  end
end
