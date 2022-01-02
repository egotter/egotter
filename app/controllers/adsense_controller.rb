class AdsenseController < ApplicationController
  include AdsenseHelper

  layout false

  before_action :reject_crawler

  def new
    html = render_to_string(partial: 'responsive', locals: {controller: params[:_controller], action: params[:_action], vertical: params[:vertical]})
    render json: {html: html}
  end
end
