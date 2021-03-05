class SearchReportResponder < AbstractMessageResponder

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
      elsif @text.match?(help_regexp)
        @help = true
      end

      @stop || @restart || @received || @help
    end

    def stop_regexp
      /検索通知(\s|　)*停止/
    end

    def restart_regexp
      /検索通知(\s|　)*再開/
    end

    def received_regexp
      /検索通知(\s|　)*(届きました|届いた)/
    end

    def help_regexp
      /検索/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @stop
        StopSearchReportRequest.create(user_id: user.id)
        CreateSearchReportStoppedMessageWorker.perform_async(user.id)
      elsif @restart
        StopSearchReportRequest.find_by(user_id: user.id)&.destroy
        CreateSearchReportRestartedMessageWorker.perform_async(user.id)
      elsif @received
        CreateSearchReportReceivedMessageWorker.perform_async(@uid)
      elsif @help
        CreateSearchReportHelpMessageWorker.perform_async(user.id)
      end
    end
  end
end
