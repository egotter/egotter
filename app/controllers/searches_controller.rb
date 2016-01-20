class SearchesController < ApplicationController

  SEARCH_MENUS = %i(show removing removed only_following only_followed mutual_friends friends_in_common followers_in_common replying replied clusters_belong_to update_history)
  NEED_VALIDATION = SEARCH_MENUS + %i(create waiting)

  before_action :invalid_twitter_id, only: NEED_VALIDATION
  before_action :suspended_user, only: NEED_VALIDATION
  before_action :protected_user_and_not_allowed_to_search, only: NEED_VALIDATION
  before_action :too_many_friends_and_followers, only: NEED_VALIDATION

  before_action :set_raw_user, only: SEARCH_MENUS
  before_action :set_searched_tw_user, only: SEARCH_MENUS

  def welcome
    redirect_to '/', notice: t('dictionary.signed_in') if user_signed_in?
  end

  def menu
    return redirect_to '/' unless user_signed_in?
    @raw_user = client.user(current_user.uid.to_i) && client.user(current_user.uid.to_i)
    if request.post?
      current_user.update(notification: params[:notification] == 'on')
      redirect_to menu_path, notice: t('dictionary.settings_saved')
    else
      render
    end
  end

  def show
    tu = @searched_tw_user
    sn = '@' + tu.screen_name
    _clusters_belong_to = (tu.clusters_belong_to(client) && tu.clusters_belong_to(client) rescue [])
    _replying = (tu.replying(client) && tu.replying(client) rescue [])
    _replied = (tu.replied(client) && tu.replied(client) rescue [])

    @menu_items = [
      {
        name: I18n.t('search_menu.removing', user: sn),
        target: tu.removing,
        path_method: method(:removing_path).to_proc
      }, {
        name: I18n.t('search_menu.removed', user: sn),
        target: tu.removed,
        path_method: method(:removed_path).to_proc
      }, {
        name: I18n.t('search_menu.only_following', user: sn),
        target: tu.only_following,
        path_method: method(:only_following_path).to_proc
      }, {
        name: I18n.t('search_menu.only_followed', user: sn),
        target: tu.only_followed,
        path_method: method(:only_followed_path).to_proc
      }, {
        name: I18n.t('search_menu.mutual_friends', user: sn),
        target: tu.mutual_friends,
        path_method: method(:mutual_friends_path).to_proc
      }, {
        name: I18n.t('search_menu.friends_in_common', user: sn, login: t('dictionary.you')),
        target: tu.friends_in_common(nil),
        path_method: method(:friends_in_common_path).to_proc
      }, {
        name: I18n.t('search_menu.followers_in_common', user: sn, login: t('dictionary.you')),
        target: tu.followers_in_common(nil),
        path_method: method(:followers_in_common_path).to_proc
      }, {
        name: I18n.t('search_menu.replying', user: sn),
        target: _replying.map { |u| u.uid = u.id; u },
        path_method: method(:replying_path).to_proc
      }, {
        name: I18n.t('search_menu.replied', user: sn),
        target: _replied.map { |u| u.uid = u.id; u },
        path_method: method(:replied_path).to_proc
      },
    ]

    @menu_clusters_belong_to = {
      name: I18n.t('search_menu.clusters_belong_to', user: sn),
      target: _clusters_belong_to,
      path_method: method(:clusters_belong_to_path).to_proc
    }

    @menu_update_history = {
      name: I18n.t('search_menu.update_history', user: sn),
      path_method: method(:update_history_path).to_proc
    }
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
    users = (@searched_tw_user.replying(client) && @searched_tw_user.replying(client) rescue [])
    @user_items = users.map { |u| u.uid = u.id; {target: u} }
  end

  # GET /searches/:screen_name/replied
  def replied
    users = (@searched_tw_user.replied(client) && @searched_tw_user.replied(client) rescue [])
    @user_items = users.map { |u| u.uid = u.id; {target: u} }
  end

  # GET /searches/:screen_name/clusters_belong_to
  def clusters_belong_to
    clusters = (@searched_tw_user.clusters_belong_to(client) && @searched_tw_user.clusters_belong_to(client) rescue [])
    @clusters_belong_to = clusters.map { |c| {target: c} }
  end

  # GET /searches/:screen_name/update_history
  def update_history
    @update_histories = TwitterUser.where(uid: @searched_tw_user.uid).order(created_at: :desc)
  end

  # GET /
  def new
    html =
      if user_signed_in?
        key = "searches:new:#{current_user.id}"
        if flash.empty?
          redis.fetch(key, 60 * 5) { render_to_string }
        else
          redis.del(key)
          render_to_string
        end
      else
        key = 'searches:new:anonymous'
        if flash.empty?
          redis.fetch(key) { render_to_string }
        else
          redis.del(key)
          render_to_string
        end
      end
    render text: html
  end

  # # GET /searches/1/edit
  # def edit
  # end

  # POST /searches
  # POST /searches.json
  def create
    begin
      searched_sn = search_sn
      searched_raw_tw_user = client.user(searched_sn) && client.user(searched_sn) # call 2 times to use cache
      searched_uid, searched_sn = searched_raw_tw_user.id.to_i, searched_raw_tw_user.screen_name.to_s
    rescue Twitter::Error::TooManyRequests => e
      return redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
    rescue => e
      logger.warn e.message
      return redirect_to '/', alert: 'error 003'
    end

    create_search_log('create', searched_uid, searched_sn, search_sn)

    FetchStatusesWorker.perform_async(searched_uid, searched_sn, (user_signed_in? ? current_user.id : nil))
    BackgroundSearchWorker.perform_async(searched_uid, searched_sn, (user_signed_in? ? current_user.id : nil), {
      login: user_signed_in?,
      login_user_id: user_signed_in? ? current_user.id : -1,
      uid: searched_uid}
    )

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
          render json: {status: false, reason: BackgroundSearchLog.fail_reason(uid)}
        else
          raise 'something is wrong'
      end
    else
      set_raw_user
      @searched_tw_user = TwitterUser.build(client, @raw_user.id.to_i, all: false)
    end
  rescue Twitter::Error::TooManyRequests => e
    if request.post?
      render json: {status: false, reason: 'too many requests'}
    else
      redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
    end
  end

  private
  def set_raw_user
    if search_id.blank?
      return redirect_to '/', alert: t('before_sign_in.blank_id')
    end

    u = client.user(search_id.to_i) && client.user(search_id.to_i)
    @raw_user = u
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  rescue => e
    logger.warn "#{e.message} #{search_id}"
    redirect_to '/', alert: t('before_sign_in.invalid_uid')
  end

  def set_searched_tw_user
    tu = TwitterUser.latest(@raw_user.id)
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

  def invalid_twitter_id
    unless search_sn =~ /\A\w{1,20}\z/
      redirect_to '/', alert: t('before_sign_in.invalid_twitter_id')
    end
  end

  def suspended_user
    unless client.user?(search_sn)
      redirect_to '/', alert: t('before_sign_in.suspended_user', user: search_sn)
    end
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def protected_user_and_not_allowed_to_search
    alert_msg = t('before_sign_in.protected_user',
                  user: search_sn,
                  sign_in_link: sign_in_link)
    raw_user = client.user(search_sn) && client.user(search_sn) # call 2 times to use cache

    return unless raw_user.protected
    return redirect_to '/', alert: alert_msg unless user_signed_in?
    return if raw_user.id.to_i == current_user.uid.to_i
    return if client.friendship?(current_user.uid.to_i, raw_user.id.to_i)

    redirect_to '/', alert: alert_msg
  rescue Twitter::Error::TooManyRequests => e
    redirect_to '/', alert: t('before_sign_in.too_many_requests', sign_in_link: sign_in_link)
  end

  def too_many_friends_and_followers
    raw_user = client.user(search_sn) && client.user(search_sn) # call 2 times to use cache
    if raw_user.friends_count + raw_user.followers_count > TwitterUser::TOO_MANY_FRIENDS
      alert_msg = t('before_sign_in.too_many_friends',
                    user: search_sn,
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

  def redis
    @redis ||= Redis.new(driver: :hiredis)
  end

  def client
    raise 'create bot' if Bot.empty?
    bot = Bot.sample
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: bot.token,
      access_token_secret: bot.secret
    }
    config.update(access_token: current_user.token, access_token_secret: current_user.secret) if user_signed_in?
    ExTwitter.new(config)
  rescue => e
    logger.warn e.message
    return redirect_to '/', alert: 'error 000'
  end
end
