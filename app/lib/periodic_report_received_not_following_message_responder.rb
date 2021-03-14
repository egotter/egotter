class PeriodicReportReceivedNotFollowingMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    REGEXP = /フォロー通知(\s|　)*届きました|フォロー(\s|　)*しました/

    def received_regexp
      REGEXP
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      CreatePeriodicReportReceivedNotFollowingMessageWorker.perform_async(user.uid)
    end
  end
end
