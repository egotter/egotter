module BlockReportConcern
  def process_block_report(dm)
    processor = BlockReportProcessor.new(dm.sender_id, dm.text)

    if processor.stop_requested?
      processor.stop_report
      return true
    end

    if processor.restart_requested?
      processor.restart_report
      return true
    end

    if processor.received?
      # Do nothing
      return true
    end

    if processor.send_requested?
      processor.send_report
      return true
    end

    false
  end

  class BlockReportProcessor
    include AbstractReportProcessor

    def stop_regexp
      /ブロ(ック|られ)通知(\s|　)*停止/
    end

    def restart_regexp
      /ブロ(ック|られ)通知(\s|　)*(再開|開始|送信)/
    end

    def received_regexp
      /ブロ(ック|られ)通知(\s|　)*届きました/
    end

    def send_regexp
      /ブロ(ック|られ)/
    end

    def stop_report
      user = validate_report_status(@uid)
      return unless user

      StopBlockReportRequest.create(user_id: user.id)
      CreateBlockReportStoppedMessageWorker.perform_async(user.id)
    end

    def restart_report
      user = validate_report_status(@uid)
      return unless user

      StopBlockReportRequest.find_by(user_id: user.id)&.destroy
      CreateBlockReportRestartedMessageWorker.perform_async(user.id)
    end

    def send_report
      user = validate_report_status(@uid)
      return unless user
      CreateBlockReportWorker.perform_async(user.id)
    end
  end
end
