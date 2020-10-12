class AdsenseController < ApplicationController
  include AdsenseHelper

  layout false

  before_action :reject_crawler
  before_action { self.access_log_disabled = true }

  def new
    @ad_id = left_slot_ad_id(params[:_controller], params[:_action], params[:vertical])
    html = render_to_string('responsive')
    render json: {html: html}
  end
end
