class MiscController < ApplicationController
  include SearchesHelper
  include Concerns::Logging

  before_action :push_referer, only: %i(menu)
  before_action :create_search_log, only: %i(menu)

  def maintenance
    render status: 503
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def sitemap
    redirect_to 'https://egotter.com/sitemap.xml.gz'
  end

  def menu
    redirect_to welcome_path(via: "#{controller_name}/#{action_name}/need_sign_in") unless user_signed_in?
  end

  def support
  end
end
