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
    @statuses = Kaminari.paginate_array(@searched_tw_user.statuses.to_a).page(params[:page]).per(100)
    @title = t('.title', user: @searched_tw_user.mention_name)
  end
end
