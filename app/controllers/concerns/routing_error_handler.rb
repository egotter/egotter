require 'active_support/concern'

module RoutingErrorHandler
  extend ActiveSupport::Concern

  def not_found
    if request.xhr?
      head :not_found
    else
      redirect_to error_pages_routing_error_path(via: current_via)
    end
  end
end
