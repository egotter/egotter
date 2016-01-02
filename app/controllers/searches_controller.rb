class SearchesController < ApplicationController
  before_action :set_search, only: [:show]

  # GET /searches
  # GET /searches.json
  def index
    @searches = Search.all
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    @tw_user = Hashie::Mash.new({image: 'http://pbs.twimg.com/profile_images/568734225050767360/cecq__2Y_normal.jpeg', location: 'どん底は大草原♪', name: 'さいころ', nickname: 'ts_3156'})
  end

  # GET /searches/new
  def new
    @search = Search.new
  end

  # # GET /searches/1/edit
  # def edit
  # end

  # POST /searches
  # POST /searches.json
  def create
    screen_name = search_params
    redirect_to search_path(1), notice: "search #{screen_name}"

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
