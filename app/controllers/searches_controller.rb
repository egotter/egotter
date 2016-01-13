class SearchesController < ApplicationController
  before_action :set_search, only: []

  # GET /searches
  # GET /searches.json
  def index
    @searches = Search.all
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    u = client.user(params[:id]) && client.user(params[:id])
    tu = @searched_tw_user = TwitterUser.latest(u.id)

    @menu_items = [
      {
        name: I18n.t('search_menu.removed_friends', user: '@' + tu.screen_name),
        target: tu.removed_friends,
        path_method: method(:removed_friends_path).to_proc
      }, {
        name: I18n.t('search_menu.removed_followers', user: '@' + tu.screen_name),
        target: tu.removed_followers,
        path_method: method(:removed_followers_path).to_proc
      }, {
        name: I18n.t('search_menu.mutual_friends', user: '@' + tu.screen_name),
        target: tu.mutual_friends,
        path_method: method(:mutual_friends_path).to_proc
      },
    ]
  end

  # GET /searches/:screen_name/removed_friends
  def removed_friends
    u = client.user(params[:screen_name]) && client.user(params[:screen_name])
    @searched_tw_user = TwitterUser.latest(u.id)
    @user_items = @searched_tw_user.removed_friends.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/removed_followers
  def removed_followers
    u = client.user(params[:screen_name]) && client.user(params[:screen_name])
    @searched_tw_user = TwitterUser.latest(u.id)
    @user_items = @searched_tw_user.removed_followers.map{|f| {target: f} }
  end

  # GET /searches/:screen_name/mutual_friends
  def mutual_friends
    u = client.user(params[:screen_name]) && client.user(params[:screen_name])
    @searched_tw_user = TwitterUser.latest(u.id)
    @user_items = @searched_tw_user.mutual_friends.map{|f| {target: f} }
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
        notice_msg = "create(not saved) #{searched_sn}"
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

    redirect_to search_path(searched_sn), notice: notice_msg
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_search
    @search = Search.find(params[:id])
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
