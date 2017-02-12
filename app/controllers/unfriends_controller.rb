class UnfriendsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper

  before_action :reject_crawler, only: %i(create)
  before_action(only: %i(create show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: %i(create show)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: %i(create show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(create show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action only: %i(new create show) do
    if request.format.html?
      push_referer
      if action_name == 'show'
        create_search_log(action: "#{controller_name}/#{get_type}")
      else
        create_search_log(action: "#{controller_name}/#{action_name}")
      end
    end
  end

  VALID_TYPES = %w(removing removed blocking_or_blocked)

  def new
    @title = t('unfriends.new.plain_title')
  end

  def create
    redirect_path = unfriend_path(screen_name: @tu.screen_name)
    if TwitterUser.exists?(uid: @tu.uid)
      redirect_to redirect_path
    else
      @screen_name = @tu.screen_name
      @redirect_path = redirect_path
      render layout: false
    end
  end

  def show
    @type = get_type

    respond_to do |format|
      format.html { render }
      format.json do
        users = Kaminari.paginate_array(@twitter_user.send(@type)).page(params[:page]).per(50)
        if users.empty?
          render json: {empty: true}, status: 200
        else
          render json: {html: render_to_string(locals: {type: @type, users: users, twitter_user: @twitter_user})}, status: 200
        end
      end
    end
  end

  private

  def get_type
    VALID_TYPES.include?(params[:type]) ? params['type'] : VALID_TYPES[0]
  end
end
