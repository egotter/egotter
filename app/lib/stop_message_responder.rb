class StopMessageResponder < AbstractMessageResponder

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

      if @text.match?(received_regexp)
        @received = true
      end
    end

    def received_regexp
      /停止|ストップ|止めて|送らないで|辞める|退会/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @received
        CreatePeriodicReportHelpMessageWorker.perform_async(user.id)
      end
    end
  end
end
