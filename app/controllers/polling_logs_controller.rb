class PollingLogsController < ApplicationController

  layout false

  def create
    status = 'true' == params[:status]
    create_polling_log(params[:uid], params[:screen_name], action: params[:_action], status: status, time: params[:time], retry_count: params[:retry_count])
    head :ok
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    head :internal_server_error
  end
end
