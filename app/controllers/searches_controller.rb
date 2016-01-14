class SearchesController < ApplicationController
  before_action :set_search, only: []

  SEARCH_MENUS = %i(show removed_friends removed_followers mutual_friends users_replying users_replied)

  before_action :set_raw_user, only: SEARCH_MENUS
  before_action :set_searched_tw_user, only: SEARCH_MENUS

  # GET /searches
  # GET /searches.json
  # def index
  #   @searches = Search.all
  # end

  # GET /searches/1
  # GET /searches/1.json
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
        target: tu.users_replying(client),
        path_method: method(:users_replying_path).to_proc
      }, {
        name: I18n.t('search_menu.users_replied', user: sn),
        target: tu.users_replying(client),
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
    @user_items = @searched_tw_user.users_replying(client).map{|f| {target: f} }
  end

  # GET /searches/:screen_name/users_replied
  def users_replied
    @user_items = @searched_tw_user.users_replied(client).map{|f| {target: f} }
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
    begin
      # TODO check with regexp -> screen_name =~ /^\w+$/ && screen_name.length <= 20
      # TODO check suspended or not exist -> client.user?(screen_name)
      # TODO check protected
      # TODO check friends + follower < limit

      searched_sn = search_params.to_s
      searched_raw_tw_user = client.user(searched_sn) && client.user(searched_sn) # call 2 times to use cache
      searched_uid, searched_sn = searched_raw_tw_user.id.to_i, searched_raw_tw_user.screen_name.to_s
    rescue => e
      logger.warn e.message
      return render text: 'error', layout: false
    end

    if (searched_tu = TwitterUser.latest(searched_uid)).present? && searched_tu.recently_created?
      notice_msg = "show #{searched_sn}"
    else
      searched_tu = TwitterUser.build_with_raw_twitter_data(client, searched_uid)
      if searched_tu.save_raw_twitter_data
        notice_msg = "create #{searched_sn}"
      else
        notice_msg = "create(#{searched_tu.errors.full_messages}) #{searched_sn}"
      end

    end

    SearchLog.create(
      login: user_signed_in?,
      login_user_id: user_signed_in? ? current_user.id : -1,
      search_uid: searched_uid,
      search_sn: searched_sn,
      search_value: search_params.to_s,
      search_menu: '',
      same_user: user_signed_in? ? current_user.uid == searched_tu.uid : false) rescue nil

    redirect_to search_path(id: searched_sn, screen_name: searched_sn), notice: notice_msg
  end

  private
  def set_raw_user
    u = client.user(params[:screen_name]) && client.user(params[:screen_name])
    @raw_user = u
  rescue => e
    logger.warn e.message
    return render text: 'error 001', layout: false
  end

  def set_searched_tw_user
    tu = TwitterUser.latest(@raw_user.id)
    if tu.blank?
      return render text: 'error 002', layout: false
    end
    @searched_tw_user = tu
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def search_params
    params[:screen_name]
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
  end
end
