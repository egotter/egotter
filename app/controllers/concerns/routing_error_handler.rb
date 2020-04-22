require 'active_support/concern'

module Concerns::RoutingErrorHandler
  extend ActiveSupport::Concern
  include Concerns::DebugConcern

  def not_found
    Airbrake.notify("No route matches #{request.fullpath}", request_details_json)
    logger.info "Not found: #{request_details}"

    if request.xhr?
      render json: {error: 'not found'}, status: :not_found

    elsif from_crawler? || request.method != 'GET'
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false

    elsif params['screen_name'].to_s.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/searches'
      @screen_name = params['screen_name']
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via'].presence || current_via('render_template')
      render template: 'searches/create', formats: %i(html), layout: false

    elsif request.fullpath.match(%r{^/https:/egotter\.com(.+)})
      redirect = "https://egotter.com#{$1}"
      logger.info "Redirect to: #{redirect}"
      redirect_to redirect, status: 301
      logger.info "#not_found redirect for backward compatibility"

    else
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
    end
  end
end
