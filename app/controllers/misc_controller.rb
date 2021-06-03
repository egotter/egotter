class MiscController < ApplicationController

  skip_before_action :current_user_not_blocker?
  before_action { head :forbidden if twitter_dm_crawler? }

  def maintenance
    render file: "#{Rails.root}/public/503.html", formats: %i(html), layout: false, status: :service_unavailable
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def specified_commercial_transactions
  end

  def refund_policy
  end

  def sitemap
    redirect_to 'https://egotter.com/sitemap.xml.gz'
  end

  def support
  end
end
