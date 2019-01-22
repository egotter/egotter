class AdsenseController < ApplicationController
  def load
    html = render_to_string partial: 'adsense/side_by_side', locals: {controller: params[:_controller], action: params[:_action], vertical: params[:vertical]}
    render json: {html: html}, status: 200
  end
end
