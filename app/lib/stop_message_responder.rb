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
      /停止|ストップ|オフ|勝手に|使わない|止めて|止まれ|止めろ|止めたい|送らないで|おくらないで|やめて|いらない|辞める|辞めたい|退会|解除|解約|無効|終了/
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
