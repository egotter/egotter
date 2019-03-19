class AdsenseController < ApplicationController
  include AdsenseHelper

  def new
    html = render_to_string template: 'adsense/new', layout: false, locals: {left_slot: left_slot(params[:_controller], params[:_action], params[:vertical])}
    render json: {html: html}
  end
end
