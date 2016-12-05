class PollingLogsController < ApplicationController
  include Concerns::Logging

  layout false

  def create
    status = 'true' == params[:status]
    create_polling_log(params[:uid], params[:screen_name], action: params[:_action], status: status, time: params[:time], retry_count: params[:retry_count])
    render nothing: true, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
