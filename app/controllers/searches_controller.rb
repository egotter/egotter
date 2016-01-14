class SearchesController < ApplicationController

  SEARCH_MENUS = %i(show removed_friends removed_followers mutual_friends users_replying users_replied)

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

  # GET /searches/new
  def new
  end

  # # GET /searches/1/edit
  # def edit
  # end

  # POST /searches
  # POST /searches.json
  def create
    unless search_sn =~ /\A\w+\z/ && search_sn.length <= 20
      return redirect_to '/', alert: 'invalid Twitter ID'
    end

    begin
      searched_sn = search_sn
      unless client.user?(searched_sn)
        logger.warn search_sn
        return redirect_to '/', alert: 'the user is suspended or not exist'
      end

      searched_raw_tw_user = client.user(searched_sn) && client.user(searched_sn) # call 2 times to use cache
      if searched_raw_tw_user.protected && (!user_signed_in? || searched_raw_tw_user.id.to_i != current_user.uid.to_i)
        return redirect_to '/', alert: 'the user is protected'
      end

      if searched_raw_tw_user.friends_count + searched_raw_tw_user.followers_count > 1500
        return redirect_to '/', alert: 'the user has too many friends and followers'
      end

      searched_uid, searched_sn = searched_raw_tw_user.id.to_i, searched_raw_tw_user.screen_name.to_s
    rescue => e
      logger.warn e.message
      return redirect_to '/', alert: 'error 003'
    end

    BackgroundSearchWorker.perform_async(searched_uid, searched_sn, (user_signed_in? ? current_user.id : nil))

    SearchLog.create(
      login: user_signed_in?,
      login_user_id: user_signed_in? ? current_user.id : -1,
      search_uid: searched_uid,
      search_sn: searched_sn,
      search_value: search_sn.to_s,
      search_menu: '',
      same_user: user_signed_in? ? current_user.uid == searched_tu.uid : false) rescue nil

    redirect_to waiting_path(screen_name: searched_sn, id: searched_uid), notice: 'test'
  end

  def waiting
    if request.post?
      raw_user = client.user(params[:id].to_i)
      # TODO need to check signing in status if the user is protected
      render json: {status: TwitterUser.latest(raw_user.id.to_i).present?}
    else
      set_raw_user
      @searched_tw_user = TwitterUser.build_with_raw_twitter_data(client, params[:id].to_i, all: false)
      render
    end
  end

  private
  def set_raw_user
    if search_id.blank?
      logger.warn 'search value is empty'
      return redirect_to '/', alert: 'error 004'
    end

    u = client.user(search_id.to_i) && client.user(search_id.to_i)
    @raw_user = u
  rescue => e
    logger.warn "#{e.message} #{search_id}"
    return redirect_to '/', alert: 'error 001'
  end

  def set_searched_tw_user
    tu = TwitterUser.latest(@raw_user.id)
    if tu.blank?
      return redirect_to '/', alert: 'error 002'
    end
    @searched_tw_user = tu
  end

  def search_sn
    params[:screen_name]
  end

  def search_id
    params[:id]
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
