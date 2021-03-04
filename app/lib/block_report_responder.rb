class BlockReportResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received?
      return false if @text.length > message_length

      if @text.match?(stop_regexp)
        @stop = true
      elsif @text.match?(restart_regexp)
        @restart = true
      elsif @text.match?(received_regexp)
        @received = true
      elsif @text.match?(send_regexp)
        @send = true
      elsif @text.match?(help_regexp)
        @help = true
      end

      @stop || @restart || @received || @send || @help
    end

    def stop_regexp
      /ブロック(通知)?(\s|　)*停止/
    end

    def restart_regexp
      /ブロック(通知)?(\s|　)*再開/
    end

    def received_regexp
      /ブロック(通知)?(\s|　)*(届きました|届いた)/
    end

    def send_regexp
      /ブロック(通知)?(\s|　)*(今すぐ)?送信/
    end

    def help_regexp
      /ブロック/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @stop
        StopBlockReportRequest.create(user_id: user.id)
        CreateBlockReportStoppedMessageWorker.perform_async(user.id)
      elsif @restart
        StopBlockReportRequest.find_by(user_id: user.id)&.destroy
        CreateBlockReportRestartedMessageWorker.perform_async(user.id)
      elsif @received
        CreateBlockReportReceivedMessageWorker.perform_async(@uid)
      elsif @send
        CreateBlockReportByUserRequestWorker.perform_async(user.id)
      elsif @help
        CreateBlockReportHelpMessageWorker.perform_async(user.id)
      end
    end
  end
end
