require 'active_support/concern'

module Concerns::RoutingErrorHandler
  extend ActiveSupport::Concern
  include Concerns::DebugConcern

  def not_found
    logger.info "Not found: #{request_details}"

    if request.xhr?
      render json: {error: 'not found'}, status: :not_found

    elsif from_crawler? || request.method != 'GET'
      self.sidebar_disabled = true
      flash.now[:alert] = routing_not_found_message
      render template: 'home/new', formats: %i(html), status: :not_found

    elsif params['screen_name'].to_s.match(Validations::ScreenNameValidator::REGEXP) && request.path == '/searches'
      @screen_name = params['screen_name']
      @redirect_path = timeline_path(screen_name: @screen_name)
      @via = params['via'].presence || build_via('render_template')
      render template: 'searches/create', formats: %i(html), layout: false

    elsif request.fullpath.match(%r{^/https:/egotter\.com(.+)})
      redirect = "https://egotter.com#{$1}"
      logger.info "Redirect to: #{redirect}"
      redirect_to redirect, status: 301

    else
      self.sidebar_disabled = true
      flash.now[:alert] = routing_not_found_message
      render template: 'home/new', formats: %i(html), status: :not_found
    end
  end

  private

  def routing_not_found_message
    t('application.routing_not_found')
  end
end
