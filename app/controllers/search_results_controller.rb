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
    @login_user = User.find_by(id: current_user_id)
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

  %i(replying replied favoriting close_friends).each do |menu|
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

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    clusters = @searched_tw_user.clusters_belong_to
    @cluster_words = clusters.keys.take(10).map { |c| {target: "#{c}#{t('searches.common.cluster')}"} }
    @graph = @searched_tw_user.clusters_belong_to_frequency_distribution
    @clusters_belong_to_cloud = @searched_tw_user.clusters_belong_to_cloud
    @tweet_text = clusters_belong_to_text(@cluster_words.take(3).map { |c| c[:target] }, @searched_tw_user)
    render json: {html: render_to_string}, status: 200
  end

  # GET /searches/:screen_name/usage_stats
  def usage_stats
    @wday, @wday_drilldown, @hour, @hour_drilldown, @usage_time = @searched_tw_user.usage_stats
    @kind = @searched_tw_user.statuses_breakdown

    hashtags = @searched_tw_user.hashtags
    @cloud = hashtags.map.with_index { |(word, count), i| {text: word, size: count, group: i % 3} }
    @hashtags = hashtags.to_a.take(10).map { |word, count| {name: word, y: count} }

    render json: {html: render_to_string}, status: 200
  end
end
