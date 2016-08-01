class SearchesController < ApplicationController
  include Validation
  include MenuItemBuilder
  include Logging
  include TweetTextHelper
  include SearchesHelper
  include PageCachesHelper

  SEARCH_MENUS = %i(friends followers removing removed blocking_or_blocked one_sided_friends one_sided_followers mutual_friends
    common_friends common_followers replying replied favoriting inactive_friends inactive_followers
    clusters_belong_to close_friends usage_stats)

  before_action :under_maintenance
  before_action :reject_crawler,      only: %i(create)
  before_action :valid_search_value?, only: %i(create)
  before_action :need_login,          only: %i(common_friends common_followers)
  before_action :set_twitter_user,    only: SEARCH_MENUS + %i(show)

  before_action only: (%i(new create waiting show) + SEARCH_MENUS) do
    if session[:sign_in_from].present?
      create_search_log(referer: session[:sign_in_from])
      session.delete(:sign_in_from)
    elsif session[:sign_out_from].present?
      create_search_log(referer: session[:sign_out_from])
      session.delete(:sign_out_from)
    else
      create_search_log
    end
  end

  def show
    @title = t('.title', user: @searched_tw_user.mention_name)
  end

  %i(friends followers removing removed blocking_or_blocked).each do |name|
    define_method(name) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(name)).items
      @title = t('.title', user: @searched_tw_user.mention_name)
      render :common_result
    end
  end

  %i(one_sided_friends one_sided_followers mutual_friends).each do |name|
    define_method(name) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(name)).items
      @graph = @searched_tw_user.mutual_friends_graph
      @tweet_text = mutual_friends_text(@searched_tw_user)
      @title = t('.title', user: @searched_tw_user.mention_name)
      render :common_result
    end
  end

  %i(common_friends common_followers).each do |name|
    define_method(name) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(name, current_user.twitter_user)).items
      @graph = @searched_tw_user.send("#{name}_graph", current_user.twitter_user)
      @tweet_text = send("#{name}_text", @user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user, @user_items.size - 3)
      @title = t('.title', user: @searched_tw_user.mention_name, login: current_user.mention_name)
      render :common_result
    end
  end

  %i(replying replied favoriting close_friends).each do |name|
    define_method(name) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(name)).items
      @graph = @searched_tw_user.send("#{name}_graph")
      @tweet_text = close_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
      @title = t('.title', user: @searched_tw_user.mention_name)
      render :common_result
    end
  end

  %i(inactive_friends inactive_followers).each do |name|
    define_method(name) do
      @user_items = TwitterUsersDecorator.new(@searched_tw_user.send(name)).items
      @graph = @searched_tw_user.send("#{name}_graph")
      @tweet_text = inactive_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
      @title = t('.title', user: @searched_tw_user.mention_name)
      render :common_result
    end
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    clusters = @searched_tw_user.clusters_belong_to
    @cluster_words = clusters.keys.slice(0, 10).map { |c| {target: "#{c}#{t('dictionary.cluster')}"} }
    @graph = @searched_tw_user.clusters_belong_to_frequency_distribution
    @clusters_belong_to_cloud = @searched_tw_user.clusters_belong_to_cloud
    @tweet_text = clusters_belong_to_text(@cluster_words.slice(0, 3).map { |c| c[:target] }, @searched_tw_user)
    @title = t('.title', user: @searched_tw_user.screen_name)
  end

  # GET /searches/:screen_name/usage_stats
  def usage_stats
    @wday_series_data_7days, @wday_drilldown_series_7days, @hour_series_data_7days, @hour_drilldown_series_7days, _ =
      @searched_tw_user.usage_stats(days: 7)
    @wday_series_data, @wday_drilldown_series, @hour_series_data, @hour_drilldown_series, @twitter_addiction_series =
      @searched_tw_user.usage_stats

    @tweet_text = usage_stats_text(@twitter_addiction_series, @searched_tw_user)
    @hashtags_cloud = @searched_tw_user.hashtags_cloud
    @hashtags_fd = @searched_tw_user.hashtags_frequency_distribution
    @title = t('.title', user: @searched_tw_user.mention_name)
  end

  # GET /
  def new
  end

  # POST /searches
  def create
    uid, screen_name = @tu.uid.to_i, @tu.screen_name
    user_id = current_user_id

    add_background_search_worker_if_needed(uid, screen_name, @tu.user_info)

    if TwitterUser.exists?(uid: uid, user_id: user_id)
      redirect_to search_path(screen_name: screen_name, id: uid)
    else
      redirect_to waiting_path(screen_name: screen_name, id: uid)
    end
  end

  # GET /searches/:screen_name/waiting
  def waiting
    uid = params.has_key?(:id) ? params[:id].match(/\A\d+\z/)[0].to_i : -1
    if uid.in?([-1, 0])
      return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end

    user_id = current_user_id
    unless ValidUidList.new(redis).exists?(uid, user_id)
      return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end

    @searched_tw_user = fetch_twitter_user_from_cache(uid, user_id)

  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    return redirect_to '/', alert: BackgroundSearchLog::SomethingError::MESSAGE
  end

  def debug
    unless request.device_type == :crawler
      logger.warn "#{self.class}##{__method__}: #{current_user_id} #{request.device_type} #{request.method} #{request.url}"
    end
    redirect_to '/'
  end

  private

  def under_maintenance
    redirect_to maintenance_path if ENV['MAINTENANCE'].present? && !admin_signed_in?
  end
end
