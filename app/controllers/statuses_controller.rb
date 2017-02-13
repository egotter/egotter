class StatusesController < ApplicationController
  include Validation
  include Concerns::Logging
  include StatusesHelper

  before_action(only: %i(show)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(show)) { existing_uid?(params[:uid].to_i) }
  before_action(only: %i(show)) { @searched_tw_user = TwitterUser.latest(params[:uid].to_i) }
  before_action(only: %i(show)) { authorized_search?(@searched_tw_user) }
  before_action only: %i(show) do
    push_referer
    create_search_log(action: :statuses)
  end

  # GET /statuses/:uid
  def show
    redirect_to friend_path(screen_name: @searched_tw_user.screen_name, type: 'statuses')
  end
end
