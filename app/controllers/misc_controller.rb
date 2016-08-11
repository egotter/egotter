class MiscController < ApplicationController
  include SearchesHelper
  include Logging

  before_action :create_search_log, only: %i(menu)

  def maintenance
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def sitemap
    @logs = BackgroundSearchLog.where(status: true, user_id: -1).order(created_at: :desc).limit(10)
    render layout: false
  end

  def menu
    redirect_to welcome_path unless user_signed_in?
  end

  def support
  end
end
