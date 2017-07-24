class SearchResultsController < ApplicationController
  include Validation
  include Concerns::Logging
  include PageCachesHelper
  include TweetTextHelper
  include SearchesHelper

  layout false

  before_action :need_login, only: %i(common_friends common_followers)
  before_action(only: %i(show) + Search::MENU) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(show) + Search::MENU) { existing_uid?(params[:uid].to_i) }
  before_action(only: %i(show) + Search::MENU) { @searched_tw_user = TwitterUser.latest(params[:uid].to_i) }
  before_action(only: %i(show) + Search::MENU) { authorized_search?(@searched_tw_user) }

  def show
    usage_stat = UsageStat.find_by(uid: @searched_tw_user.uid)
    @graph_wday = usage_stat&.wday || {}
    @tweet_clusters = usage_stat&.tweet_clusters || {}
    html = ::Cache::PageCache.new.fetch(@searched_tw_user.uid) { render_to_string }
    render json: {html: html}, status: 200
  rescue => e
    bot = Bot.find_by(token: client.access_token)&.screen_name
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{@searched_tw_user.uid} #{@searched_tw_user.screen_name} #{bot} #{request.device_type} #{request.browser}"
    logger.info e.backtrace.grep_v(/\.bundle/).empty? ? e.backtrace.join("\n") : e.backtrace.grep_v(/\.bundle/).join("\n")
    render nothing: true, status: 500
  end

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
end
