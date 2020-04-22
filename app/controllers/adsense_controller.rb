class AdsenseController < ApplicationController
  include AdsenseHelper

  layout false

  def new
    if params[:_controller] == 'timelines' && params[:_action] == 'show' && params[:vertical] == 'top'
      @ad_id = responsive_ad_id(params[:_controller], params[:_action], params[:vertical])
      html = render_to_string 'responsive'
    else
      @ad_id = left_slot_ad_id(params[:_controller], params[:_action], params[:vertical])
      html = render_to_string
    end

    render json: {html: html}
  end
end
