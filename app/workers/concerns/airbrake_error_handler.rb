require 'active_support/concern'

module Concerns::AirbrakeErrorHandler
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def notify_airbrake(exception, params = {})
    params.merge!(cause: exception.cause) if exception.cause
    begin
      notice = Airbrake.build_notice(exception, params)
      notice[:context][:component] = 'sidekiq'
      Airbrake.notify(notice)
    rescue => e
      logger.warn "#{__method__} #{e.inspect}"
      logger.info e.backtrace.join("\n")
    end

    logger.info "#{exception.inspect} #{params.inspect} #{"Caused by #{exception.cause.inspect}" if exception.cause}"
    logger.info exception.backtrace.join("\n")
  end
end
