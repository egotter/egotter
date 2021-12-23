class StopAllReportsResponder < AbstractMessageResponder

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
      end

      @stop
    end

    def stop_regexp
      /(全て|すべて|全部|ぜんぶ)の?通知(\s|　)*停止/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @stop
        StopAllReportsWorker.perform_async(user.id)
        CreateAllReportsStoppedMessageWorker.perform_async(user.id)
      end
    end
  end
end
