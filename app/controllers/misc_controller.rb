class MiscController < ApplicationController

  before_action :push_referer, only: %i(menu)
  before_action :create_search_log, only: %i(menu)

  def maintenance
    render file: "#{Rails.root}/public/503.html", formats: %i(html), layout: false, status: :service_unavailable
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def specified_commercial_transactions
  end

  def sitemap
    redirect_to 'https://egotter.com/sitemap.xml.gz'
  end

  def support
  end
end
