class AdsenseController < ApplicationController
  def load
    html = render_to_string partial: 'common/adsense', locals: {action: params[:action], vertical: params[:vertical]}
    render json: {html: html}, status: 200
  end
end
