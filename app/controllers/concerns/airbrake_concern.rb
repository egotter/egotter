require 'active_support/concern'

module Concerns::AirbrakeConcern
  extend ActiveSupport::Concern

  def notify_airbrake(*args)
    super
    logger.info "#{__method__} #{controller_name}##{action_name} #{(caller[0][/`([^']*)'/, 1] rescue '')} #{args[0].inspect}"
    logger.info args[0].backtrace.join("\n")
  end
end
