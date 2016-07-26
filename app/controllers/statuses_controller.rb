class StatusesController < ApplicationController
  include Logging
  include SearchesHelper

  before_action :set_twitter_user, only: %i(show)
  before_action only: %i(show) do
    create_search_log(action: :statuses)
  end

  # GET /statuses/:id
  def show
    @status_items = apply_kaminari(@searched_tw_user.statuses)
    @title = t('search_menu.statuses', user: @searched_tw_user.mention_name)
  end

  private

  def apply_kaminari(statuses)
    Kaminari.paginate_array(statuses).page(params[:page]).per(100)
  end
end
