class SearchesController < ApplicationController

  DEBUG_PAGES = %i(debug clear_result_cache)
  SEARCH_MENUS = %i(show statuses friends followers removing removed_by one_sided_friends one_sided_followers mutual_friends
    common_friends common_followers replying replied favoriting inactive_friends inactive_followers
    clusters_belong_to close_friends usage_stats update_histories)
  NEED_VALIDATION = SEARCH_MENUS + %i(create waiting)
  NEED_LOGIN = %i(common_friends common_followers)

  before_action :under_maintenance,      except: (%i(maintenance) + DEBUG_PAGES)
  before_action :need_login,             only: NEED_LOGIN
  before_action :invalid_screen_name,    only: NEED_VALIDATION
  before_action :build_twitter_user,     only: NEED_VALIDATION
  before_action :suspended_account,      only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :unauthorized_account,   only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :too_many_friends,       only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :build_search_histories, except: (%i(create) + DEBUG_PAGES)

  before_action :set_twitter_user,       only: SEARCH_MENUS
  before_action :create_log,             only: SEARCH_MENUS


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

  def welcome
    redirect_to '/', notice: t('dictionary.signed_in') if user_signed_in?
  end

  # not using befor_action
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
    start_time = Time.zone.now
    tu = @searched_tw_user

    if result_cache_exists?
      logger.debug "cache found action=#{action_name} key=#{result_cache_key}"
      return render text: replace_csrf_meta_tags(result_cache, Time.zone.now - start_time, redis.ttl(result_cache_key), tu.search_log.call_count)
    end

    sn = '@' + tu.screen_name

    @menu_items = [
      {
        name: t('search_menu.removing', user: sn),
        target: tu.removing,
        graph: tu.removing_graph,
        path_method: method(:removing_path).to_proc
      }, {
        name: t('search_menu.removed_by', user: sn),
        target: tu.removed_by,
        graph: tu.removed_by_graph,
        path_method: method(:removed_by_path).to_proc
      }, {
        name: t('search_menu.mutual_friends', user: sn),
        target: tu.mutual_friends,
        graph: tu.mutual_friends_graph,
        path_method: method(:mutual_friends_path).to_proc
      }, {
        name: t('search_menu.one_sided_friends', user: sn),
        target: tu.one_sided_friends,
        graph: tu.one_sided_friends_graph,
        path_method: method(:one_sided_friends_path).to_proc
      }, {
        name: t('search_menu.one_sided_followers', user: sn),
        target: tu.one_sided_followers,
        graph: tu.one_sided_followers_graph,
        path_method: method(:one_sided_followers_path).to_proc
      }, {
        name: t('search_menu.replying', user: sn),
        target: tu.replying, # calling users
        graph: tu.replying_graph,
        path_method: method(:replying_path).to_proc
      }, {
        name: t('search_menu.replied', user: sn),
        target: tu.replied, # no calling
        graph: tu.replied_graph,
        path_method: method(:replied_path).to_proc
      }, {
        name: t('search_menu.favoriting', user: sn),
        target: tu.favoriting, # no calling
        graph: tu.favoriting_graph,
        path_method: method(:favoriting_path).to_proc
      }, {
        name: t('search_menu.inactive_friends', user: sn),
        target: tu.inactive_friends,
        graph: tu.inactive_friends_graph,
        path_method: method(:inactive_friends_path).to_proc
      }, {
        name: t('search_menu.inactive_followers', user: sn),
        target: tu.inactive_followers,
        graph: tu.inactive_followers_graph,
        path_method: method(:inactive_followers_path).to_proc
      },
    ]

    @menu_common_friends_and_followers =
      if search_oneself?(tu.uid)
        [
          {
            name: t('search_menu.common_friends', user: sn, login: t('dictionary.you')),
            target: [],
            path_method: method(:common_friends_path).to_proc
          }, {
            name: t('search_menu.common_followers', user: sn, login: t('dictionary.you')),
            target: [],
            path_method: method(:common_followers_path).to_proc
          },
        ]
      elsif search_others?(tu.uid)
        [
          {
            name: t('search_menu.common_friends', user: sn, login: t('dictionary.you')),
            target: tu.common_friends(current_user.twitter_user),
            graph: tu.common_friends_graph(current_user.twitter_user),
            path_method: method(:common_friends_path).to_proc
          }, {
            name: t('search_menu.common_followers', user: sn, login: t('dictionary.you')),
            target: tu.common_followers(current_user.twitter_user),
            graph: tu.common_followers_graph(current_user.twitter_user),
            path_method: method(:common_followers_path).to_proc
          },
        ]
      elsif !user_signed_in?
        [
          {
            name: t('search_menu.common_friends', user: sn, login: t('dictionary.you')),
            target: [],
            path_method: method(:common_friends_path).to_proc
          }, {
            name: t('search_menu.common_followers', user: sn, login: t('dictionary.you')),
            target: [],
            path_method: method(:common_followers_path).to_proc
          },
        ]
      end

    @menu_close_friends = {
      name: t('search_menu.close_friends', user: sn),
      target: tu.close_friends(cache: :read), # no calling
      graph: tu.close_friends_graph(cache: :read),
      path_method: method(:close_friends_path).to_proc
    }

    @menu_usage_stats = {
      name: t('search_menu.usage_stats', user: sn),
      graph: tu.usage_stats_graph,
      path_method: method(:usage_stats_path).to_proc
    }

    _clusters_belong_to = tu.clusters_belong_to
    @menu_clusters_belong_to = {
      name: t('search_menu.clusters_belong_to', user: sn),
      target: _clusters_belong_to,
      graph: tu.clusters_belong_to_frequency_distribution,
      screen_name: tu.screen_name,
      text: "#{_clusters_belong_to.map{|c| "#{c}#{t('dictionary.cluster')}" }.join(t('dictionary.delim'))}",
      tweet_text: "#{t('search_menu.clusters_belong_to', user: sn)}\n#{_clusters_belong_to.map{|c| "##{c}#{t('dictionary.cluster')}" }.join(' ')}\n#{t('dictionary.continue_reading')}http://example.com",
      path_method: method(:clusters_belong_to_path).to_proc
    }

    @menu_update_histories = {
      name: t('search_menu.update_histories', user: sn),
      path_method: method(:update_histories_path).to_proc
    }

    @title = t('search_menu.search_result', user: "@#{@searched_tw_user.screen_name}")

    render text: replace_csrf_meta_tags(set_result_cache, Time.zone.now - start_time, redis.ttl(result_cache_key), tu.search_log.call_count, tu.client.call_count)

  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  # GET /searches/:screen_name/statuses
  def statuses
    @status_items = build_tweet_items(@searched_tw_user.statuses)
    @title = t('search_menu.statuses', user: "@#{@searched_tw_user.screen_name}")
  end

  # GET /searches/:screen_name/friends
  def friends
    @user_items = build_user_items(@searched_tw_user.friends)
    @title = t('search_menu.friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/followers
  def followers
    @user_items = build_user_items(@searched_tw_user.followers)
    @title = t('search_menu.followers', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/removing
  def removing
    @user_items = build_user_items(@searched_tw_user.removing)
    @title = t('search_menu.removing', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/removed_by
  def removed_by
    @user_items = build_user_items(@searched_tw_user.removed_by)
    @title = t('search_menu.removed_by', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/one_sided_friends
  def one_sided_friends
    @user_items = build_user_items(@searched_tw_user.one_sided_friends)
    @graph = @searched_tw_user.mutual_friends_graph
    @tweet_text = view_context.mutual_friends_text(@searched_tw_user)
    @title = t('search_menu.one_sided_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/one_sided_followers
  def one_sided_followers
    @user_items = build_user_items(@searched_tw_user.one_sided_followers)
    @graph = @searched_tw_user.mutual_friends_graph
    @tweet_text = view_context.mutual_friends_text(@searched_tw_user)
    @title = t('search_menu.one_sided_followers', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/mutual_friends
  def mutual_friends
    @user_items = build_user_items(@searched_tw_user.mutual_friends)
    @graph = @searched_tw_user.mutual_friends_graph
    @tweet_text = view_context.mutual_friends_text(@searched_tw_user)
    @title = t('search_menu.mutual_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/common_friends
  def common_friends
    @user_items = build_user_items(@searched_tw_user.common_friends(current_user.twitter_user))
    @graph = @searched_tw_user.common_friends_graph(current_user.twitter_user)
    @tweet_text = view_context.common_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user, @user_items.size - 3)
    @title = t('search_menu.common_friends', user: "@#{@searched_tw_user.screen_name}", login: "@#{current_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/common_followers
  def common_followers
    @user_items = build_user_items(@searched_tw_user.common_followers(current_user.twitter_user))
    @graph = @searched_tw_user.common_followers_graph(current_user.twitter_user)
    @tweet_text = view_context.common_followers_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user, @user_items.size - 3)
    @title = t('search_menu.common_followers', user: "@#{@searched_tw_user.screen_name}", login: "@#{current_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/replying
  def replying
    @user_items = build_user_items(@searched_tw_user.replying) # call users
    @graph = @searched_tw_user.replying_graph
    @tweet_text = view_context.close_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.replying', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/replied
  def replied
    @user_items = build_user_items(@searched_tw_user.replied)
    @graph = @searched_tw_user.replied_graph
    @tweet_text = view_context.close_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.replied', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/favoriting
  def favoriting
    @user_items = build_user_items(@searched_tw_user.favoriting)
    @graph = @searched_tw_user.favoriting_graph
    @tweet_text = view_context.close_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.favoriting', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/inactive_friends
  def inactive_friends
    @user_items = build_user_items(@searched_tw_user.inactive_friends)
    @graph = @searched_tw_user.inactive_friends_graph
    @tweet_text = view_context.inactive_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.inactive_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/inactive_followers
  def inactive_followers
    @user_items = build_user_items(@searched_tw_user.inactive_followers)
    @graph = @searched_tw_user.inactive_followers_graph
    @tweet_text = view_context.inactive_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.inactive_followers', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    clusters = @searched_tw_user.clusters_belong_to
    @cluster_words = clusters.keys.slice(0, 10).map { |c| {target: "#{c}#{t('dictionary.cluster')}"} }
    @graph = @searched_tw_user.clusters_belong_to_frequency_distribution
    @clusters_belong_to_cloud = @searched_tw_user.clusters_belong_to_cloud
    @tweet_text = view_context.clusters_belong_to_text(@cluster_words.slice(0, 3).map { |c| c[:target] }, @searched_tw_user)
    @title = t('search_menu.clusters_belong_to', user: @searched_tw_user.screen_name)
  end

  # GET /searches/:screen_name/close_friends
  def close_friends
    @user_items = build_user_items(@searched_tw_user.close_friends)
    @graph = @searched_tw_user.close_friends_graph
    @tweet_text = view_context.close_friends_text(@user_items.slice(0, 3).map{|i| i[:target] }, @searched_tw_user)
    @title = t('search_menu.close_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/usage_stats
  def usage_stats
    @wday_series_data_7days, @wday_drilldown_series_7days, @hour_series_data_7days, @hour_drilldown_series_7days, _ =
      @searched_tw_user.usage_stats(days: 7)
    @wday_series_data, @wday_drilldown_series, @hour_series_data, @hour_drilldown_series, @twitter_addiction_series =
      @searched_tw_user.usage_stats

    @tweet_text = view_context.usage_stats_text(@twitter_addiction_series, @searched_tw_user)
    @hashtags_cloud = @searched_tw_user.hashtags_cloud
    @hashtags_fd = @searched_tw_user.hashtags_frequency_distribution
    @title = t('search_menu.usage_stats', user: "@#{@searched_tw_user.screen_name}")
  end

  # GET /searches/:screen_name/update_histories
  def update_histories
    @update_histories = TwitterUser.where(uid: @searched_tw_user.uid).order(created_at: :desc)
  end

  # GET /
  def new
    @tweet_text = t('tweet_text.top', kaomoji: Kaomoji.happy)
    key = "searches:new:#{current_user_id}"
    html =
      if flash.empty? && !delay_occurs?
        redis.fetch(key) { render_to_string }
      else
        render_to_string
      end
    render text: replace_csrf_meta_tags(html, 0.0, redis.ttl(key))
  end

  # POST /searches
  def create
    searched_uid, searched_sn = @twitter_user.uid.to_i, @twitter_user.screen_name.to_s

    if searched_uid_exists?(searched_uid)
      logger.debug "searched_uid found #{searched_uid}:#{searched_sn}"
    else
      BackgroundSearchWorker.perform_async(
        searched_uid, searched_sn, current_user_id, @twitter_user.too_many_friends?)
      add_searched_uid(searched_uid)
    end

    if result_cache_exists?
      logger.debug "cache found action=#{action_name} key=#{result_cache_key}"
      return redirect_to search_path(screen_name: searched_sn, id: searched_uid)
    end

    redirect_to waiting_path(screen_name: searched_sn, id: searched_uid)
  end

  # GET /searches/:screen_name/waiting
  # POST /searches/:screen_name/waiting
  def waiting
    if request.post?
      uid = @twitter_user.uid.to_i
      user_id = current_user_id
      case
        when BackgroundSearchLog.processing?(uid, user_id)
          render json: {status: false, reason: 'processing'}
        when BackgroundSearchLog.success?(uid, user_id)
          render json: {status: true}
        when BackgroundSearchLog.fail?(uid, user_id)
          render json: {status: false,
                        reason: BackgroundSearchLog.fail_reason(uid, user_id),
                        message: BackgroundSearchLog.fail_message(uid, user_id)}
        else
          raise BackgroundSearchLog::SomethingIsWrong
      end
    else
      @searched_tw_user = @twitter_user
    end
  end

  def debug
    @debug_info = Hashie::Mash.new(JSON.parse(redis.get(Redis.debug_info_key) || '{}'))
    @last_1hour = 1.hour.ago..Time.now
    @last_1day = 1.day.ago..Time.now
    @last_1week = (1.week.ago + 1.day)..Time.now
    render layout: false
  end

  def clear_result_cache
    redirect_to '/' unless request.post?
    redirect_to '/' unless current_user.admin?
    redis.clear_result_cache
    redirect_to '/'
  end

  private
  def set_twitter_user
    tu = @twitter_user.latest_me
    if tu.blank?
      # admin_signed_in? returns true and TwitterUser is deleted
      logger.warn '@twitter_user.latest_me is blank'
      del_result_cache
      return create
    end
    tu.assign_attributes(client: client, egotter_context: 'search')
    @searched_tw_user = tu
  end

  def search_sn
    params[:screen_name]
  end

  def search_id
    params[:id].to_i
  end

  def need_login
    redirect_to '/', alert: t('before_sign_in.need_login', sign_in_link: sign_in_link) unless user_signed_in?
  end

  def invalid_screen_name
    if TwitterUser.new(screen_name: search_sn).invalid_screen_name?
      redirect_to '/', alert: t('before_sign_in.invalid_twitter_id')
    end
  end

  def build_twitter_user
    user = client.user(search_sn)
    @twitter_user =
      TwitterUser.build_by_user(user, client: client, user_id: current_user_id, egotter_context: 'search')
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  rescue Twitter::Error::NotFound => e
    redirect_to '/', alert: t('before_sign_in.not_found')
  rescue Twitter::Error::Unauthorized => e
    alert_msg =
      if user_signed_in?
        t("after_sign_in.unauthorized", sign_out_link: sign_out_link)
      else
        t("before_sign_in.unauthorized", sign_in_link: sign_in_link)
      end
    redirect_to '/', alert: alert_msg.html_safe
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
    redirect_to '/', alert: t('before_sign_in.something_is_wrong', sign_in_link: sign_in_link)
  end

  def suspended_account
    if @twitter_user.suspended_account?
      redirect_to '/', alert: t('before_sign_in.suspended_user', user: twitter_link(search_sn))
    end
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def unauthorized_account
    alert_msg = t('before_sign_in.protected_user',
                  user: twitter_link(@twitter_user.screen_name),
                  sign_in_link: sign_in_link)
    return redirect_to '/', alert: alert_msg if @twitter_user.unauthorized?
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def too_many_friends
    # do nothing
    # if @twitter_user.too_many_friends?
    # end
  end

  def build_user_items(items)
    friendships =
      if user_signed_in? && current_user.twitter_user?
        current_user.twitter_user.friend_uids
      else
        []
      end
    me = user_signed_in? ? current_user.uid.to_i : nil
    targets = items.map { |u| {target: u, friendship: friendships.include?(u.uid.to_i), me: (u.uid.to_i == me)} }
    Kaminari.paginate_array(targets).page(params[:page]).per(25)
  end

  def build_tweet_items(items)
    Kaminari.paginate_array(items.map { |t| {target: t} }).page(params[:page]).per(100)
  end

  def create_log
    SearchLog.create(
      session_id: session.id,
      user_id: current_user_id,
      uid: @searched_tw_user.uid,
      screen_name: @searched_tw_user.screen_name,
      action: action_name,
      ego_surfing: (user_signed_in? && current_user.uid.to_i == @searched_tw_user.uid.to_i))
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message}"
  end

  def twitter_link(screen_name)
    view_context.link_to("@#{screen_name}", "https://twitter.com/#{screen_name}", target: '_blank')
  end

  def redis
    @redis ||= Redis.client
  end

  def result_cache_key
    "searches:show:#{current_user_id}:#{@twitter_user.uid}-#{@twitter_user.screen_name}"
  end

  def result_cache_exists?
    redis.exists(result_cache_key)
  end

  def result_cache
    redis.get(result_cache_key)
  end

  RESULT_CACHE_TTL = Rails.configuration.x.constants['result_cache_ttl']

  def set_result_cache
    html = render_to_string
    redis.setex(result_cache_key, RESULT_CACHE_TTL, html)
    html
  end

  def del_result_cache
    redis.del(result_cache_key)
  end

  def searched_uids_key
    Redis.foreground_search_searched_uids_key
  end

  def searched_uid_exists?(uid)
    rem_expired_searched_uid
    redis.zrank(searched_uids_key, "#{current_user_id}:#{uid}").present?
  end

  def add_searched_uid(uid)
    rem_expired_searched_uid
    redis.zadd(searched_uids_key, Time.zone.now.to_i, "#{current_user_id}:#{uid}")
  end

  def rem_expired_searched_uid
    seconds = Rails.configuration.x.constants['background_search_worker_recently_searched_threshold']
    redis.zremrangebyscore(searched_uids_key, 0, Time.zone.now.to_i - seconds)
  end

  def rem_searched_uid(uid)
    redis.rem_searched_uid(uid)
  end

  def replace_csrf_meta_tags(html, time = 0.0, ttl = 0, log_call_count = -1, action_call_count = -1)
    html.sub('<!-- csrf_meta_tags -->', view_context.csrf_meta_tags).
      sub('<!-- search_elapsed_time -->', view_context.number_with_precision(time, precision: 1)).
      sub('<!-- cache_ttl -->', view_context.number_with_precision(ttl.to_f / 3600.seconds, precision: 1)).
      sub('<!-- log_call_count -->', log_call_count.to_s).
      sub('<!-- action_call_count -->', action_call_count.to_s)
  end

  def client
    @client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  rescue => e
    logger.warn e.message
    return redirect_to '/', alert: 'error 000'
  end

  def build_search_histories
    @search_histories =
      if user_signed_in?
        searched_uids = BackgroundSearchLog.success_logs(current_user.id, 20).pluck(:uid).unix_uniq.slice(0, 10)
        build_user_items(searched_uids.map { |uid| TwitterUser.latest(uid.to_i, current_user.id) }.compact)
      else
        []
      end
  end

  def delay_occurs?
    result = SidekiqHandler.delay_occurs?
    result ? redis.incr_delay_occurs_count : redis.incr_delay_does_not_occur_count
    result
  end

  def current_user_id
    user_signed_in? ? current_user.id : -1
  end

  def under_maintenance
    redirect_to maintenance_path if ENV['MAINTENANCE'].present? && !admin_signed_in?
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == ENV['DEBUG_USERNAME'] && pass == ENV['DEBUG_PASSWORD']
    end
  end
end
