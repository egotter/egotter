class ModalOpenLogsController < ApplicationController

  layout false

  def create
    # TODO specify only params[:via]
    create_modal_open_log(params[:via] || params[:name])
    head :ok
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    head :internal_server_error
  end
end
