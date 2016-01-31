class SearchesController < ApplicationController

  SEARCH_MENUS = %i(show removing removed only_following only_followed mutual_friends
    friends_in_common followers_in_common replying replied inactive_friends inactive_followers clusters_belong_to update_histories)
  NEED_VALIDATION = SEARCH_MENUS + %i(create waiting)

  before_action :set_twitter_user,     only: NEED_VALIDATION
  before_action :invalid_screen_name,  only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :suspended_account,    only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :unauthorized_account, only: NEED_VALIDATION, unless: :result_cache_exists?
  before_action :too_many_friends,     only: NEED_VALIDATION, unless: :result_cache_exists?

  before_action :set_searched_tw_user, only: SEARCH_MENUS

  before_action :basic_auth, only: %i(debug)

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
    tu = @searched_tw_user

    if result_cache_exists?
      logger.debug "cache found action=#{action_name} key=#{result_cache_key}"
      return render text: replace_csrf_meta_tags(result_cache)
    end

    tu.client = client
    tu.login_user = user_signed_in? ? current_user : nil
    sn = '@' + tu.screen_name
    _replied = (tu.replied && tu.replied rescue [])

    @menu_items = [
      {
        name: t('search_menu.removing', user: sn),
        target: tu.removing,
        path_method: method(:removing_path).to_proc
      }, {
        name: t('search_menu.removed', user: sn),
        target: tu.removed,
        path_method: method(:removed_path).to_proc
      }, {
        name: t('search_menu.only_following', user: sn),
        target: tu.only_following,
        path_method: method(:only_following_path).to_proc
      }, {
        name: t('search_menu.only_followed', user: sn),
        target: tu.only_followed,
        path_method: method(:only_followed_path).to_proc
      }, {
        name: t('search_menu.mutual_friends', user: sn),
        target: tu.mutual_friends,
        path_method: method(:mutual_friends_path).to_proc
      }, {
        name: t('search_menu.friends_in_common', user: sn, login: t('dictionary.you')),
        target: tu.friends_in_common(nil),
        path_method: method(:friends_in_common_path).to_proc
      }, {
        name: t('search_menu.followers_in_common', user: sn, login: t('dictionary.you')),
        target: tu.followers_in_common(nil),
        path_method: method(:followers_in_common_path).to_proc
      }, {
        name: t('search_menu.replying', user: sn),
        target: tu.replying,
        path_method: method(:replying_path).to_proc
      }, {
        name: t('search_menu.replied', user: sn),
        target: _replied.map { |u| u.uid = u.id; u },
        path_method: method(:replied_path).to_proc
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

    render text: replace_csrf_meta_tags(set_result_cache)

  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  # GET /searches/:screen_name/removing
  def removing
    @user_items = @searched_tw_user.removing.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/removed
  def removed
    @user_items = @searched_tw_user.removed.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/only_following
  def only_following
    @user_items = @searched_tw_user.only_following.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/only_followed
  def only_followed
    @user_items = @searched_tw_user.only_followed.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/mutual_friends
  def mutual_friends
    @user_items = @searched_tw_user.mutual_friends.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/friends_in_common
  def friends_in_common
    @user_items = @searched_tw_user.friends_in_common(nil).map{|f| {target: f} }
  end

  # GET /searches/:screen_name/followers_in_common
  def followers_in_common
    @user_items = @searched_tw_user.followers_in_common(nil).map{|f| {target: f} }
  end

  # GET /searches/:screen_name/replying
  def replying
    @searched_tw_user.client = client
    @user_items = @searched_tw_user.replying.map { |u| {target: u} }
  end

  # GET /searches/:screen_name/replied
  def replied
    @searched_tw_user.client = client
    users = (@searched_tw_user.replied && @searched_tw_user.replied rescue [])
    @user_items = users.map { |u| u.uid = u.id; {target: u} }
  end

  # GET /searches/:screen_name/inactive_friends
  def inactive_friends
    @searched_tw_user.login_user = user_signed_in? ? current_user : nil
    @user_items = @searched_tw_user.inactive_friends.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/inactive_followers
  def inactive_followers
    @searched_tw_user.login_user = user_signed_in? ? current_user : nil
    @user_items = @searched_tw_user.inactive_followers.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    @searched_tw_user.client = client
    clusters = (@searched_tw_user.clusters_belong_to && @searched_tw_user.clusters_belong_to rescue [])
    @clusters_belong_to = clusters.map { |c| {target: c} }
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
    render text: replace_csrf_meta_tags(html)
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
    debug_key = 'update_job_dispatcher:debug'
    @debug_info = JSON.parse(redis.get(debug_key) || '{}')
    @last_1hour = 1.hour.ago..Time.now
    render layout: false
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

  def set_twitter_user
    @twitter_user = TwitterUser.new(uid: search_id, screen_name: search_sn)
    @twitter_user.client = client
    @twitter_user.login_user = current_user
    @twitter_user.fetch_user?
    @twitter_user.fetch_user
    @twitter_user.egotter_context = 'search'
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

  def replace_csrf_meta_tags(html)
    html.sub(/csrf_meta_tags/, "#{view_context.csrf_meta_tags}<!-- replaced -->")
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
