class SearchesController < ApplicationController

  SEARCH_MENUS = %i(show removed_friends removed_followers mutual_friends users_replying users_replied)
  NEED_VALIDATION = SEARCH_MENUS + %i(create waiting)

  before_action :invalid_twitter_id, only: NEED_VALIDATION
  before_action :suspended_user, only: NEED_VALIDATION
  before_action :protected_user_and_not_allowed_to_search, only: NEED_VALIDATION
  before_action :too_many_friends_and_followers, only: NEED_VALIDATION

  before_action :set_raw_user, only: SEARCH_MENUS
  before_action :set_searched_tw_user, only: SEARCH_MENUS

  def welcome

  end

  def show
    tu = @searched_tw_user
    sn = '@' + tu.screen_name
    @menu_items = [
      {
        name: I18n.t('search_menu.removed_friends', user: sn),
        target: tu.removed_friends,
        path_method: method(:removed_friends_path).to_proc
      }, {
        name: I18n.t('search_menu.removed_followers', user: sn),
        target: tu.removed_followers,
        path_method: method(:removed_followers_path).to_proc
      }, {
        name: I18n.t('search_menu.mutual_friends', user: sn),
        target: tu.mutual_friends,
        path_method: method(:mutual_friends_path).to_proc
      }, {
        name: I18n.t('search_menu.users_replying', user: sn),
        target: tu.users_replying(client).map do |u|
          uu = Hashie::Mash.new(u.to_hash.slice(*TwitterUser::SAVE_KEYS)); uu.uid = uu.id; uu
        end,
        path_method: method(:users_replying_path).to_proc
      }, {
        name: I18n.t('search_menu.users_replied', user: sn),
        target: tu.users_replied(client).map do |u|
          uu = Hashie::Mash.new(u.to_hash.slice(*TwitterUser::SAVE_KEYS)); uu.uid = uu.id; uu
        end,
        path_method: method(:users_replied_path).to_proc
      },
    ]
  end

  # GET /searches/:screen_name/removed_friends
  def removed_friends
    @user_items = @searched_tw_user.removed_friends.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/removed_followers
  def removed_followers
    @user_items = @searched_tw_user.removed_followers.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/mutual_friends
  def mutual_friends
    @user_items = @searched_tw_user.mutual_friends.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/users_replying
  def users_replying
    @user_items = @searched_tw_user.users_replying(client).map do |u|
      uu = Hashie::Mash.new(u.to_hash.slice(*TwitterUser::SAVE_KEYS)); uu.uid = uu.id
      {target: uu}
    end
  end

  # GET /searches/:screen_name/users_replied
  def users_replied
    @user_items = @searched_tw_user.users_replied(client).map do |u|
      uu = Hashie::Mash.new(u.to_hash.slice(*TwitterUser::SAVE_KEYS)); uu.uid = uu.id
      {target: uu}
    end
  end

  # GET /
  def new
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
    rescue => e
      logger.warn e.message
      return redirect_to '/', alert: 'error 003'
    end

    create_search_log('create', searched_uid, searched_sn, search_sn)

    FetchStatusesWorker.perform_async(searched_uid, searched_sn, (user_signed_in? ? current_user.id : nil))
    BackgroundSearchWorker.perform_async(searched_uid, searched_sn, (user_signed_in? ? current_user.id : nil), {
      login: user_signed_in?,
      login_user_id: user_signed_in? ? current_user.id : -1,
      search_uid: searched_uid,
      search_sn: searched_sn,
      search_value: search_sn,
      search_menu: 'background',
      same_user: (user_signed_in? && current_user.uid.to_i == searched_uid.to_i)}
    )

    redirect_to waiting_path(screen_name: searched_sn, id: searched_uid), notice: 'test'
  end

  # POST /searches/:screen_name/waiting
  def waiting
    if request.post?
      raw_user = client.user(params[:id].to_i)
      render json: {status: SearchLog.background_search_success?(raw_user.id)}
    else
      set_raw_user
      @searched_tw_user = TwitterUser.build_with_raw_twitter_data(client, @raw_user.id.to_i, all: false)
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
