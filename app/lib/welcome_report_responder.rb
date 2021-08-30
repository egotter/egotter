class WelcomeReportResponder < AbstractMessageResponder

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
      elsif @text.match?(send_regexp)
        @send = true
      elsif @text.match?(help_regexp)
        @help = true
      end
    end

    def received_regexp
      /初期設定(\s|　)*届きました/
    end

    def send_regexp
      /初期設定(\s|　)*(開始|送信)/
    end

    def help_regexp
      /初期|設定/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @received
        CreateWelcomeReportReceivedMessageWorker.perform_async(@uid)
      elsif @send
        CreateWelcomeMessageWorker.perform_async(user.id)
      elsif @help
        CreateWelcomeReportHelpMessageWorker.perform_async(user.id)
      end
    end
  end
end
