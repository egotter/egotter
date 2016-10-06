class UpdateHistoriesController < ApplicationController
  include Validation
  include Logging
  include SearchesHelper

  before_action(only: %i(show)) { valid_uid?(params[:id].to_i) }
  before_action(only: %i(show)) { existing_uid?(params[:id].to_i) }
  before_action(only: %i(show)) { @searched_tw_user = TwitterUser.latest(params[:id].to_i) }
  before_action(only: %i(show)) { authorized_search?(@searched_tw_user) }
  before_action only: %i(show) do
    push_referer
    create_search_log(action: :update_histories)
  end

  # GET /update_histories/:id
  def show
    @title = t('update_histories.show.title', user: @searched_tw_user.mention_name)
    @update_histories = UpdateHistories.new(@searched_tw_user.uid)
  end
end
