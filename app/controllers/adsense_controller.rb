class AdsenseController < ApplicationController
  include AdsenseHelper

  def new
    @left_slot_ad_id = left_slot_ad_id(params[:_controller], params[:_action], params[:vertical])
    html = render_to_string layout: false
    render json: {html: html}
  end
end
