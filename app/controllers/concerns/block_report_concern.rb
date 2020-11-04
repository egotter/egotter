require 'active_support/concern'

module BlockReportConcern
  extend ActiveSupport::Concern

  STOP_BLOCK_REPORT_REGEXP = /ブロック通知(\s|　)*停止/

  def stop_block_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(STOP_BLOCK_REPORT_REGEXP)
  end

  RESTART_BLOCK_REPORT_REGEXP = /ブロック通知(\s|　)*(再開|開始)/

  def restart_block_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(RESTART_BLOCK_REPORT_REGEXP)
  end

  def stop_block_report(dm)
    unless (user = User.where(authorized: true).find_by(uid: dm.sender_id))
      return
    end

    StopBlockReportRequest.create(user_id: user.id)
    CreateBlockReportStoppedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def restart_block_report(dm)
    unless (user = User.where(authorized: true).find_by(uid: dm.sender_id))
      return
    end

    StopBlockReportRequest.find_by(user_id: user.id)&.destroy
    CreateBlockReportRestartedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
