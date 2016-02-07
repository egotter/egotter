class SearchesController < ApplicationController

  SEARCH_MENUS = %i(show statuses friends followers removing removed one_sided_following one_sided_followers mutual_friends
    common_friends common_followers replying replied favoriting inactive_friends inactive_followers
    clusters_belong_to close_friends usage_stats update_histories)
  NEED_VALIDATION = SEARCH_MENUS + %i(create waiting)
  NEED_LOGIN = %i(common_friends common_followers debug clear_result_cache)
  DEBUG_PAGES = %i(debug clear_result_cache)

  before_action :before_action_start,  only: NEED_VALIDATION
  before_action :need_login,           only: NEED_LOGIN
  before_action :set_twitter_user,     only: NEED_VALIDATION
  before_action :invalid_screen_name,  only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :suspended_account,    only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :unauthorized_account, only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :too_many_friends,     only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :before_action_finish, only: NEED_VALIDATION

  before_action :set_searched_tw_user, only: SEARCH_MENUS

  before_action :basic_auth, only: DEBUG_PAGES

  def welcome
    redirect_to '/', notice: t('dictionary.signed_in') if user_signed_in?
  end

  # not using befor_action
  def menu
    return redirect_to welcome_path unless user_signed_in?
    @raw_user = client.user(current_user.uid.to_i) && client.user(current_user.uid.to_i)
    if request.post?
      current_user.update(notification: params[:notification] == 'on')
      redirect_to menu_path, notice: t('dictionary.settings_saved')
    else
      searched_uids = BackgroundSearchLog.success_logs(current_user.id, 20).pluck(:uid).unix_uniq.slice(0, 10)
      @user_items = searched_uids.map { |uid| TwitterUser.latest(uid.to_i) }.compact.map { |tu| {target: tu} }
      render
    end
  end

  def show
    start_time = Time.zone.now
    tu = @searched_tw_user

    if !nocache && result_cache_exists?
      logger.debug "cache found action=#{action_name} key=#{result_cache_key}"
      return render text: replace_csrf_meta_tags(result_cache, Time.zone.now - start_time)
    end

    tu.client = client
    tu.login_user = user_signed_in? ? current_user : nil
    sn = '@' + tu.screen_name

    @menu_items = [
      {
        name: t('search_menu.close_friends', user: sn),
        target: tu.close_friends,
        graph: tu.close_friends_graph,
        path_method: method(:close_friends_path).to_proc
      }, {
        name: t('search_menu.usage_stats', user: sn),
        target: [],
        path_method: method(:usage_stats_path).to_proc
      }, {
        name: t('search_menu.removing', user: sn),
        target: tu.removing,
        path_method: method(:removing_path).to_proc
      }, {
        name: t('search_menu.removed', user: sn),
        target: tu.removed,
        path_method: method(:removed_path).to_proc
      }, {
        name: t('search_menu.one_sided_following', user: sn),
        target: tu.one_sided_following,
        graph: tu.one_sided_following_graph,
        path_method: method(:one_sided_following_path).to_proc
      }, {
        name: t('search_menu.one_sided_followers', user: sn),
        target: tu.one_sided_followers,
        graph: tu.one_sided_followers_graph,
        path_method: method(:one_sided_followers_path).to_proc
      }, {
        name: t('search_menu.mutual_friends', user: sn),
        target: tu.mutual_friends,
        graph: tu.mutual_friends_graph,
        path_method: method(:mutual_friends_path).to_proc
      }, {
        name: t('search_menu.replying', user: sn),
        target: tu.replying,
        path_method: method(:replying_path).to_proc
      }, {
        name: t('search_menu.replied', user: sn),
        target: tu.replied,
        path_method: method(:replied_path).to_proc
      }, {
        name: t('search_menu.favoriting', user: sn),
        target: tu.favoriting,
        path_method: method(:favoriting_path).to_proc
      }, {
        name: t('search_menu.inactive_friends', user: sn),
        target: tu.inactive_friends,
        path_method: method(:inactive_friends_path).to_proc
      }, {
        name: t('search_menu.inactive_followers', user: sn),
        target: tu.inactive_followers,
        path_method: method(:inactive_followers_path).to_proc
      },
    ]

    @menu_common_friends_and_followers =
      if user_signed_in? && current_user.uid.to_i == tu.uid.to_i
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
      elsif user_signed_in? && current_user.uid.to_i != tu.uid.to_i
        [
          {
            name: t('search_menu.common_friends', user: sn, login: "@#{current_user.screen_name}"),
            target: tu.common_friends(current_user.twitter_user),
            path_method: method(:common_friends_path).to_proc
          }, {
            name: t('search_menu.common_followers', user: sn, login: "@#{current_user.screen_name}"),
            target: tu.common_followers(current_user.twitter_user),
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

    _clusters_belong_to = tu.clusters_belong_to
    @menu_clusters_belong_to = {
      name: t('search_menu.clusters_belong_to', user: sn),
      target: _clusters_belong_to,
      screen_name: tu.screen_name,
      text: "#{_clusters_belong_to.map{|c| "#{c}#{t('dictionary.cluster')}" }.join(t('dictionary.delim'))}",
      tweet_text: "#{t('search_menu.clusters_belong_to', user: sn)}\n#{_clusters_belong_to.map{|c| "##{c}#{t('dictionary.cluster')}" }.join(' ')}\n#{t('dictionary.continue_reading')}http://example.com",
      path_method: method(:clusters_belong_to_path).to_proc
    }

    @menu_update_histories = {
      name: t('search_menu.update_histories', user: sn),
      path_method: method(:update_histories_path).to_proc
    }

    render text: replace_csrf_meta_tags(set_result_cache, Time.zone.now - start_time)

  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  # GET /searches/:screen_name/statuses
  def statuses
    @status_items = @searched_tw_user.statuses.map{|f| {target: f} }
    @name = t('search_menu.statuses', user: "@#{@searched_tw_user.screen_name}")
  end

  # GET /searches/:screen_name/friends
  def friends
    @user_items = build_user_items(@searched_tw_user.friends)
    @name = t('search_menu.friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/followers
  def followers
    @user_items = build_user_items(@searched_tw_user.followers)
    @name = t('search_menu.followers', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/removing
  def removing
    @user_items = build_user_items(@searched_tw_user.removing)
    @name = t('search_menu.removing', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/removed
  def removed
    @user_items = build_user_items(@searched_tw_user.removed)
    @name = t('search_menu.removed', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/one_sided_following
  def one_sided_following
    @user_items = build_user_items(@searched_tw_user.one_sided_following)
    @name = t('search_menu.one_sided_following', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/one_sided_followers
  def one_sided_followers
    @user_items = build_user_items(@searched_tw_user.one_sided_followers)
    @name = t('search_menu.one_sided_followers', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/mutual_friends
  def mutual_friends
    @user_items = build_user_items(@searched_tw_user.mutual_friends)
    @name = t('search_menu.mutual_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/common_friends
  def common_friends
    @user_items = build_user_items(@searched_tw_user.common_friends(current_user.twitter_user))
    @name = t('search_menu.common_friends', user: "@#{@searched_tw_user.screen_name}", login: "@#{current_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/common_followers
  def common_followers
    @user_items = build_user_items(@searched_tw_user.common_followers(current_user.twitter_user))
    @name = t('search_menu.common_followers', user: "@#{@searched_tw_user.screen_name}", login: "@#{current_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/replying
  def replying
    @searched_tw_user.client = client
    @user_items = build_user_items(@searched_tw_user.replying)
    @name = t('search_menu.replying', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/replied
  def replied
    @searched_tw_user.client = client
    @user_items = build_user_items(@searched_tw_user.replied)
    @name = t('search_menu.replied', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/favoriting
  def favoriting
    @searched_tw_user.client = client
    @user_items = build_user_items(@searched_tw_user.favoriting)
    @name = t('search_menu.favoriting', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/inactive_friends
  def inactive_friends
    @searched_tw_user.login_user = user_signed_in? ? current_user : nil
    @user_items = build_user_items(@searched_tw_user.inactive_friends)
    @name = t('search_menu.inactive_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/inactive_followers
  def inactive_followers
    @searched_tw_user.login_user = user_signed_in? ? current_user : nil
    @user_items = build_user_items(@searched_tw_user.inactive_followers)
    @name = t('search_menu.inactive_followers', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    @searched_tw_user.client = client
    clusters = (@searched_tw_user.clusters_belong_to && @searched_tw_user.clusters_belong_to rescue [])
    @clusters_belong_to = clusters.map { |c| {target: c} }
  end

  # GET /searches/:screen_name/close_friends
  def close_friends
    @searched_tw_user.client = client
    @user_items = build_user_items(@searched_tw_user.close_friends)
    @name = t('search_menu.close_friends', user: "@#{@searched_tw_user.screen_name}")
    render :common_result
  end

  # GET /searches/:screen_name/usage_stats
  def usage_stats
    @searched_tw_user.client = client
    @wday_series_data_7days, @wday_drilldown_series_7days, @hour_series_data_7days, @hour_drilldown_series_7days =
      @searched_tw_user.usage_stats(days: 7)
    @wday_series_data, @wday_drilldown_series, @hour_series_data, @hour_drilldown_series =
      @searched_tw_user.usage_stats
    @name = t('search_menu.usage_stats', user: "@#{@searched_tw_user.screen_name}")
  end

  # GET /searches/:screen_name/update_histories
  def update_histories
    @update_histories = TwitterUser.where(uid: @searched_tw_user.uid).order(created_at: :desc)
  end

  # GET /
  def new
    key = "searches:new:#{user_or_anonymous}"
    html =
      if flash.empty?
        redis.fetch(key, 60 * 180) { render_to_string }
      else
        render_to_string
      end
    render text: replace_csrf_meta_tags(html, 0.0)
  end

  # # GET /searches/1/edit
  # def edit
  # end

  # POST /searches
  # POST /searches.json
  def create
    begin
      searched_raw_tw_user = client.user(search_sn) && client.user(search_sn) # call 2 times to use cache
      searched_uid, searched_sn = searched_raw_tw_user.id.to_i, searched_raw_tw_user.screen_name.to_s
    rescue Twitter::Error::TooManyRequests => e
      return redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
    rescue => e
      logger.warn e.message
      return redirect_to '/', alert: t('before_sign_in.something_is_wrong', sign_in_link: sign_in_link)
    end

    create_search_log('create', searched_uid, searched_sn, search_sn)

    BackgroundSearchWorker.perform_async(searched_uid, searched_sn, (user_signed_in? ? current_user.id : nil), {
      user_id: user_signed_in? ? current_user.id : -1,
      uid: searched_uid}
    )

    if result_cache_exists?
      logger.debug "cache found action=#{action_name} key=#{result_cache_key}"
      return redirect_to search_path(screen_name: searched_sn, id: searched_uid)
    end

    redirect_to waiting_path(screen_name: searched_sn, id: searched_uid)
  end

  # POST /searches/:screen_name/waiting
  def waiting
    if request.post?
      raw_user = client.user(params[:id].to_i)
      uid = raw_user.id.to_i
      case
        when BackgroundSearchLog.processing?(uid)
          render json: {status: false, reason: 'processing'}
        when BackgroundSearchLog.success?(uid)
          render json: {status: true}
        when BackgroundSearchLog.fail?(uid)
          render json: {status: false,
                        reason: BackgroundSearchLog.fail_reason(uid),
                        message: BackgroundSearchLog.fail_message(uid)}
        else
          raise BackgroundSearchLog::SomethingIsWrong
      end
    else
      @searched_tw_user = TwitterUser.build(client, @twitter_user.uid.to_i, all: false)
    end
  rescue Twitter::Error::TooManyRequests => e
    if request.post?
      render json: {status: false, reason: BackgroundSearchLog::TooManyRequests}
    else
      redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
    end
  end

  def debug
    redirect_to '/' unless current_user.admin?
    debug_key = 'update_job_dispatcher:debug'
    @debug_info = JSON.parse(redis.get(debug_key) || '{}')
    @last_1hour = 1.hour.ago..Time.now
    render layout: false
  end

  def clear_result_cache
    redirect_to '/' unless request.post?
    redirect_to '/' unless current_user.admin?
    redis.clear_result_cache
    redirect_to '/'
  end

  private
  def set_searched_tw_user
    tu = TwitterUser.latest(@twitter_user.uid.to_i)
    if tu.blank?
      return redirect_to '/', alert: t('before_sign_in.blank_search_result')
    end
    @searched_tw_user = tu
  end

  def search_sn
    params[:screen_name]
  end

  def search_id
    params[:id].to_i
  end

  def nocache
    params[:nocache].present?
  end

  def before_action_start
    @before_action_start = Time.zone.now
  end

  def before_action_finish
    end_time = Time.zone.now
    @before_action_elapsed_time = end_time - @before_action_start
    logger.debug "DEBUG: before_action total time #{action_name} #{@before_action_elapsed_time}s"
  end

  def need_login
    redirect_to '/', alert: t('before_sign_in.need_login', sign_in_link: sign_in_link) unless user_signed_in?
  end

  def set_twitter_user
    @twitter_user = TwitterUser.new(uid: search_id, screen_name: search_sn)
    @twitter_user.client = client
    @twitter_user.login_user = current_user
    @twitter_user.fetch_user?
    @twitter_user.fetch_user
    @twitter_user.egotter_context = 'search'
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  rescue Twitter::Error::NotFound => e
    redirect_to '/', alert: t('before_sign_in.not_found')
  rescue => e
    redirect_to '/', alert: t('before_sign_in.something_is_wrong', sign_in_link: sign_in_link)
  end

  def invalid_screen_name
    if @twitter_user.invalid_screen_name?
      redirect_to '/', alert: t('before_sign_in.invalid_twitter_id')
    end
  end

  def suspended_account
    unless @twitter_user.fetch_user?
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
    if @twitter_user.too_many_friends?
      alert_msg = t('before_sign_in.too_many_friends',
                    user: twitter_link(@twitter_user.screen_name),
                    friends: @twitter_user.friends_count,
                    followers: @twitter_user.followers_count,
                    sign_in_link: sign_in_link)
      redirect_to '/', alert: alert_msg
    end
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def build_user_items(items)
    friendships =
      if user_signed_in? && current_user.twitter_user?
        TwitterUser.latest(current_user.uid.to_i).friend_uids
      else
        []
      end
    items.map { |u| {target: u, friendship: friendships.include?(u.uid.to_i)} }
  end

  def create_search_log(name, search_uid, search_sn, search_value)
    SearchLog.create(
      login: user_signed_in?,
      login_user_id: user_signed_in? ? current_user.id : -1,
      search_uid: search_uid,
      search_sn: search_sn,
      search_value: search_value,
      search_menu: name,
      same_user: (user_signed_in? && current_user.uid.to_i == search_uid.to_i))
  rescue => e
    logger.warn "create_search_log #{e.message}"
  end

  def sign_in_link
    view_context.link_to(t('dictionary.sign_in'), welcome_path)
  end

  def twitter_link(screen_name)
    view_context.link_to("@#{screen_name}", "https://twitter.com/#{screen_name}", target: '_blank')
  end

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def result_cache_key
    "searches:show:#{user_or_anonymous}:#{uid_and_screen_name(@twitter_user.uid, @twitter_user.screen_name)}"
  end

  def result_cache_exists?
    return false
    redis.exists(result_cache_key)
  end

  def result_cache
    redis.get(result_cache_key)
  end

  def set_result_cache
    html = render_to_string
    redis.setex(result_cache_key, 60 * 180, html) # 180 minutes
    html
  end

  def replace_csrf_meta_tags(html, time)
    html.sub('<!-- csrf_meta_tags -->', "#{view_context.csrf_meta_tags}<!-- replaced -->").
      sub('<!-- search_elapsed_time -->', view_context.number_with_precision(time, precision: 1))
  end

  def user_or_anonymous
    user_signed_in? ? current_user.id.to_s : 'anonymous'
  end

  def uid_and_screen_name(uid, sn)
    "#{uid}-#{sn}"
  end

  def client
    @client ||= (user_signed_in? ? current_user.api_client : Bot.api_client)
  rescue => e
    logger.warn e.message
    return redirect_to '/', alert: 'error 000'
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == ENV['DEBUG_USERNAME'] && pass == ENV['DEBUG_PASSWORD']
    end if Rails.env.production?
  end
end
