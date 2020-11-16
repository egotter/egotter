module SearchReportConcern
  def process_search_report(dm)
    processor = SearchReportProcessor.new(dm.sender_id, dm.text)

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
      # Do nothing
      return true
    end

    false
  end

  class SearchReportProcessor
    include AbstractReportProcessor

    def stop_regexp
      /検索通知(\s|　)*停止/
    end

    def restart_regexp
      /検索通知(\s|　)*(再開|開始|送信)/
    end

    def received_regexp
      /検索通知(\s|　)*届きました/
    end

    def send_regexp
      /検索通知/
    end

    def stop_report
      user = validate_report_status(@uid)
      return unless user

      StopSearchReportRequest.create(user_id: user.id)
      CreateSearchReportStoppedMessageWorker.perform_async(user.id)
    end

    def restart_report
      user = validate_report_status(@uid)
      return unless user

      StopSearchReportRequest.find_by(user_id: user.id)&.destroy
      CreateSearchReportRestartedMessageWorker.perform_async(user.id)
    end
  end
end
