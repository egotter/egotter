require 'active_support/concern'

module RoutingErrorHandler
  extend ActiveSupport::Concern

  def not_found
    if request.xhr?
      head :not_found
    else
      create_error_log(__method__, 'not_found')
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
    end
  end
end
