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

      if @text.match?(stop_all_regexp)
        @stop_all = true
      elsif @text.match?(stop_regexp)
        @stop = true
      end
    end

    def stop_all_regexp
      /(全て|すべて|全部|ぜんぶ)の?通知(\s|　)*停止/
    end

    def stop_regexp
      /停止|ストップ|オフ|勝手に|使わない|止めて|止まれ|止めろ|止めたい|送らないで|おくらないで|やめて|いらない|辞める|辞めたい|退会|解除|無効|終了/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @stop_all
        StopAllReportsWorker.perform_async(user.id)
        CreateAllReportsStoppedMessageWorker.perform_async(user.id)
      elsif @stop
        CreatePeriodicReportHelpMessageWorker.perform_async(user.id)
      end
    end
  end
end
