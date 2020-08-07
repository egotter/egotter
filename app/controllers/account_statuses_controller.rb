class AccountStatusesController < ApplicationController

  before_action :require_login!
  before_action :reject_crawler
  before_action { valid_uid?(params[:uid]) }

  def show
    render json: {message: 'not_found'}
  end
end
