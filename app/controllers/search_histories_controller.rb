class SearchHistoriesController < ApplicationController
  include SearchesHelper
  include SearchHistoriesHelper

  layout false

  def index
    @in_modal = params.has_key?(:in_modal) && params[:in_modal] == 'true' ? true : false
    html = redis.fetch("search_histories:#{current_user_id}:#{@in_modal}", ttl: 5.minutes) do
      @search_histories = build_search_histories(current_user_id)
      render_to_string
    end

    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
