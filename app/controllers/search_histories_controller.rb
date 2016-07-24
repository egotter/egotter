class SearchHistoriesController < ApplicationController
  include SearchesHelper
  include SearchHistoriesHelper

  before_action :build_search_histories, only: %i(index)

  def index
    in_modal = params.has_key?(:in_modal) && params[:in_modal] == 'true' ? true : false
    html = render_to_string(partial: 'searches/search_histories', locals: {search_histories: build_search_histories, in_modal: in_modal})
    render json: {status: 200, html: html}, status: 200
  rescue => e
    logger.warn "#{e}: #{e.message}"
    render json: {status: 500}, status: 500
  end
end
