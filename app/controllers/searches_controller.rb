class SearchesController < ApplicationController
  include Validation
  include MenuItemBuilder
  include Logging
  include TweetTextHelper
  include SearchesHelper
  include PageCachesHelper

  DEBUG_PAGES = %i(debug clear_result_cache)
  SEARCH_MENUS = %i(friends followers removing removed blocking_or_blocked one_sided_friends one_sided_followers mutual_friends
    common_friends common_followers replying replied favoriting inactive_friends inactive_followers
    clusters_belong_to close_friends usage_stats)
  NEED_LOGIN = %i(common_friends common_followers)

  before_action :reject_crawler,         only: %i(create)
  before_action :under_maintenance,      except: (%i(maintenance) + DEBUG_PAGES)
  before_action :need_login,             only: NEED_LOGIN
  before_action :valid_search_value?,    only: %i(create)
  before_action :set_twitter_user,       only: SEARCH_MENUS + %i(show)

  before_action only: (%i(new create waiting show menu) + SEARCH_MENUS) do
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

  before_action :basic_auth, only: DEBUG_PAGES

  def maintenance
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def sitemap
    @logs = BackgroundSearchLog.where(status: true, user_id: -1).order(created_at: :desc).limit(10)
    render layout: false
  end

  # not using before_action
  def menu
    return redirect_to welcome_path unless user_signed_in?
    if request.patch?
      current_user.notification.update(params.require(:notification).permit(:email, :dm, :news, :search))
      redirect_to menu_path, notice: t('dictionary.settings_saved')
    else
      render
    end
  end

  def support
  end

  def show
    @title = t('search_menu.search_result', user: @searched_tw_user.mention_name)
  end

  # GET /searches/:screen_name/friends
  def friends
    @user_items = build_user_items(@searched_tw_user.friends)
    @title = t('search_menu.friends', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/followers
  def followers
    @user_items = build_user_items(@searched_tw_user.followers)
    @title = t('search_menu.followers', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/removing
  def removing
    @user_items = build_user_items(@searched_tw_user.removing)
    @title = t('search_menu.removing', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/removed
  def removed
    @user_items = build_user_items(@searched_tw_user.removed)
    @title = t('search_menu.removed', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/blocking_or_blocked
  def blocking_or_blocked
    @user_items = build_user_items(@searched_tw_user.blocking_or_blocked)
    @title = t('search_menu.blocking_or_blocked', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/one_sided_friends
  def one_sided_friends
    @user_items = build_user_items(@searched_tw_user.one_sided_friends)
    @graph = @searched_tw_user.mutual_friends_graph
    @tweet_text = mutual_friends_text(@searched_tw_user)
    @title = t('search_menu.one_sided_friends', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/one_sided_followers
  def one_sided_followers
    @user_items = build_user_items(@searched_tw_user.one_sided_followers)
    @graph = @searched_tw_user.mutual_friends_graph
    @tweet_text = mutual_friends_text(@searched_tw_user)
    @title = t('search_menu.one_sided_followers', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/mutual_friends
  def mutual_friends
    @user_items = build_user_items(@searched_tw_user.mutual_friends)
    @graph = @searched_tw_user.mutual_friends_graph
    @tweet_text = mutual_friends_text(@searched_tw_user)
    @title = t('search_menu.mutual_friends', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/common_friends
  def common_friends
    @user_items = build_user_items(@searched_tw_user.common_friends(current_user.twitter_user))
    @graph = @searched_tw_user.common_friends_graph(current_user.twitter_user)
    @tweet_text = common_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user, @user_items.size - 3)
    @title = t('search_menu.common_friends', user: @searched_tw_user.mention_name, login: current_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/common_followers
  def common_followers
    @user_items = build_user_items(@searched_tw_user.common_followers(current_user.twitter_user))
    @graph = @searched_tw_user.common_followers_graph(current_user.twitter_user)
    @tweet_text = common_followers_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user, @user_items.size - 3)
    @title = t('search_menu.common_followers', user: @searched_tw_user.mention_name, login: current_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/replying
  def replying
    @user_items = build_user_items(@searched_tw_user.replying) # call users
    @graph = @searched_tw_user.replying_graph
    @tweet_text = close_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.replying', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/replied
  def replied
    @user_items = build_user_items(@searched_tw_user.replied)
    @graph = @searched_tw_user.replied_graph
    @tweet_text = close_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.replied', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/favoriting
  def favoriting
    @user_items = build_user_items(@searched_tw_user.favoriting)
    @graph = @searched_tw_user.favoriting_graph
    @tweet_text = close_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.favoriting', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/inactive_friends
  def inactive_friends
    @user_items = build_user_items(@searched_tw_user.inactive_friends)
    @graph = @searched_tw_user.inactive_friends_graph
    @tweet_text = inactive_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.inactive_friends', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/inactive_followers
  def inactive_followers
    @user_items = build_user_items(@searched_tw_user.inactive_followers)
    @graph = @searched_tw_user.inactive_followers_graph
    @tweet_text = inactive_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.inactive_followers', user: @searched_tw_user.mention_name)
    render :common_result
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    clusters = @searched_tw_user.clusters_belong_to
    @cluster_words = clusters.keys.slice(0, 10).map { |c| {target: "#{c}#{t('dictionary.cluster')}"} }
    @graph = @searched_tw_user.clusters_belong_to_frequency_distribution
    @clusters_belong_to_cloud = @searched_tw_user.clusters_belong_to_cloud
    @tweet_text = clusters_belong_to_text(@cluster_words.slice(0, 3).map { |c| c[:target] }, @searched_tw_user)
    @title = t('search_menu.clusters_belong_to', user: @searched_tw_user.screen_name)
  end

  # GET /searches/:screen_name/close_friends
  def close_friends
    @user_items = build_user_items(@searched_tw_user.close_friends)
    @graph = @searched_tw_user.close_friends_graph
    @tweet_text = close_friends_text(@user_items.slice(0, 3).map { |i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.close_friends', user: @searched_tw_user.mention_name)
    render :common_result
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
    @title = t('search_menu.usage_stats', user: @searched_tw_user.mention_name)
  end

  # GET /
  def new
    @tweet_text = t('tweet_text.top', kaomoji: Kaomoji.happy)
    key = "searches:#{current_user_id}:new"
    html =
      if ENV['PAGE_CACHE'] == '1' && flash.empty?
        redis.fetch(key) { render_to_string }
      else
        render_to_string
      end
    render text: replace_csrf_meta_tags(html, 0.0, redis.ttl(key))
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

  def clear_result_cache
    return redirect_to '/' unless request.post?
    return redirect_to '/' unless current_user.admin?
    PageCache.new(redis).clear
    redirect_to '/'
  end

  private

  def replace_csrf_meta_tags(html, time = 0.0, ttl = 0, log_call_count = -1, action_call_count = -1)
    html.sub('<!-- csrf_meta_tags -->', view_context.csrf_meta_tags).
      sub('<!-- search_elapsed_time -->', view_context.number_with_precision(time, precision: 1)).
      sub('<!-- cache_ttl -->', view_context.number_with_precision(ttl.to_f / 3600.seconds, precision: 1)).
      sub('<!-- log_call_count -->', log_call_count.to_s).
      sub('<!-- action_call_count -->', action_call_count.to_s)
  end

  def under_maintenance
    redirect_to maintenance_path if ENV['MAINTENANCE'].present? && !admin_signed_in?
  end
end
