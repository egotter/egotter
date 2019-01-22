class SearchHistoriesController < ApplicationController
  def load
    html = render_to_string partial: 'layouts/search_histories'
    render json: {html: html}
  end
end
