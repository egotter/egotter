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
    admin_user = User.find_by(provider: 'twitter', uid: '58135830')
    config = {
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: admin_user.token,
      access_token_secret: admin_user.secret
    }
    config.update(access_token: current_user.token, access_token_secret: current_user.secret) if user_signed_in?
    client = ExTwitter.new(config)

    searched_sn = params[:id].to_s
    if (tu = TwitterUser.order(created_at: :desc).find_by(screen_name: searched_sn)) && tu.recently_created?
      @searched_tw_user = tu
    else
      searched_raw_tw_user = client.user(searched_sn) && client.user(searched_sn) # call 2 times to use cache
      friends, followers = client.friends_and_followers(searched_raw_tw_user.id) && client.friends_and_followers(searched_raw_tw_user.id)
      @searched_tw_user = TwitterUser.save_raw_user(searched_raw_tw_user)
      @searched_tw_user.save_raw_friends(friends)
      @searched_tw_user.save_raw_followers(followers)
    end

    @login_tw_user = client.user(current_user.uid.to_i) if user_signed_in?
  end

  # GET /searches/new
  def new
    # @search = Search.new
  end

  # # GET /searches/1/edit
  # def edit
  # end

  # POST /searches
  # POST /searches.json
  def create
    screen_name = search_params
    redirect_to search_path(screen_name), notice: "search #{screen_name}"

    # respond_to do |format|
    #   if @search.save
    #     format.html { redirect_to @search, notice: 'Search was successfully created.' }
    #     format.json { render :show, status: :created, location: @search }
    #   else
    #     format.html { render :new }
    #     format.json { render json: @search.errors, status: :unprocessable_entity }
    #   end
    # end
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
end
