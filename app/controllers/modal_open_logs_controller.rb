class ModalOpenLogsController < ApplicationController
  include Concerns::Logging

  layout false

  def create
    # TODO specify only params[:via]
    create_modal_open_log(
      params[:uid],
      params[:screen_name],
      via: (params[:via] || params[:name])
    )
    render nothing: true, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
