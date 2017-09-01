class SearchHistoriesController < ApplicationController
  def load
    html = render_to_string partial: 'layouts/search_histories'
    render json: {html: html}, status: 200
  end
end
