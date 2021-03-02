class MuteReportResponder < AbstractMessageResponder

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
      /ミュート(通知)?(\s|　)*停止/
    end

    def restart_regexp
      /ミュート(通知)?(\s|　)*再開/
    end

    def received_regexp
      /ミュート(通知)?(\s|　)*(届きました|届いた)/
    end

    def send_regexp
      /ミュート(通知)?(\s|　)*送信/
    end

    def help_regexp
      /ミュート/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user
      return unless user.admin? # Test release

      # TODO MuteReport Implement MuteReportReceivedMessageConfirmation

      if @stop
        StopMuteReportRequest.create(user_id: user.id)
        CreateMuteReportStopRequestedWorker.perform_async(user.id)
      elsif @restart
        StopMuteReportRequest.find_by(user_id: user.id)&.destroy
        CreateMuteReportRestartRequestedWorker.perform_async(user.id)
      elsif @received
        CreateMuteReportReceivedMessageWorker.perform_async(user.id)
      elsif @send
        CreateMuteReportByUserRequestWorker.perform_async(user.id)
      elsif @help
        CreateMuteReportHelpMessageWorker.perform_async(user.id)
      end
    end
  end
end
