require 'active_support/concern'

module BlockReportConcern
  extend ActiveSupport::Concern
  include PeriodicReportConcern

  SEND_BLOCK_REPORT_REGEXP = /ブロック通知/

  def send_block_report_requested?(text)
    text.length < 15 && text.match?(SEND_BLOCK_REPORT_REGEXP)
  end

  BLOCK_REPORT_RECEIVED_REGEXP = /ブロック通知(\s|　)*届きました/

  def block_report_received?(text)
    text.length < 15 && text.match?(BLOCK_REPORT_RECEIVED_REGEXP)
  end

  STOP_BLOCK_REPORT_REGEXP = /ブロック通知(\s|　)*停止/

  def stop_block_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(STOP_BLOCK_REPORT_REGEXP)
  end

  RESTART_BLOCK_REPORT_REGEXP = /ブロック通知(\s|　)*(再開|開始|送信)/

  def restart_block_report_requested?(text)
    text.length < 15 && text.match?(RESTART_BLOCK_REPORT_REGEXP)
  end

  module_function :restart_block_report_requested?

  def send_block_report(uid)
    user = validate_periodic_report_status(uid)
    return unless user

    CreateBlockReportWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end

  def stop_block_report(dm)
    user = validate_periodic_report_status(dm.sender_id)
    return unless user

    StopBlockReportRequest.create(user_id: user.id)
    CreateBlockReportStoppedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def restart_block_report(dm)
    user = validate_periodic_report_status(dm.sender_id)
    return unless user

    StopBlockReportRequest.find_by(user_id: user.id)&.destroy
    CreateBlockReportRestartedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
