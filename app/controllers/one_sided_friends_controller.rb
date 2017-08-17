class OneSidedFriendsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper

  before_action :reject_crawler, only: %i(create)
  before_action(only: %i(create show)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
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
      create_search_log
    end
  end

  VALID_TYPES = %w(one_sided_friends one_sided_followers mutual_friends)

  def new
    @title = t('one_sided_friends.new.plain_title')
  end

  def create
    redirect_path = one_sided_friend_path(screen_name: @tu.screen_name)
    if TwitterUser.exists?(uid: @tu.uid)
      redirect_to redirect_path
    else
      @screen_name = @tu.screen_name
      @redirect_path = redirect_path
      @via = params['via']
      render template: 'searches/create', layout: false
    end
  end

  def show
    @type = get_type

    respond_to do |format|
      format.html { render }
      format.json do
        users = @twitter_user.send(@type).page(params[:page]).per(50)
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
