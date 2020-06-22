class AdsenseController < ApplicationController
  include AdsenseHelper

  layout false

  before_action { self.access_log_disabled = true }

  def new
    @ad_id = left_slot_ad_id(params[:_controller], params[:_action], params[:vertical])
    if RESPONSIVE_AD_IDS.include?(@ad_id)
      html = render_to_string 'responsive'
    else
      html = render_to_string
    end

    render json: {html: html}
  end
end
