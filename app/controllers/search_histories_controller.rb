class SearchHistoriesController < ApplicationController
  include SearchesHelper
  include SearchHistoriesHelper

  layout false

  def index
    in_modal = params.has_key?(:in_modal) && params[:in_modal] == 'true' ? true : false
    html = render_to_string(locals: {search_histories: build_search_histories, in_modal: in_modal})
    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
