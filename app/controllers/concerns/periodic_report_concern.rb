module PeriodicReportConcern
  include ReportStatusValidator

  def process_periodic_report(dm)
    processor = PeriodicReportProcessor.new(dm.sender_id, dm.text)

    if processor.stop_requested?
      processor.stop_report
      return true
    end

    if processor.restart_requested?
      processor.restart_report
      return true
    end

    if processor.continue_requested?
      processor.continue_report
      return true
    end

    # if processor.received?
    #   # Do nothing
    #   return true
    # end

    if processor.send_requested?
      processor.send_report
      return true
    end

    false
  end

  def process_egotter_requested_periodic_report(dm)
    processor = PeriodicReportProcessor.new(dm.recipient_id, dm.text)

    if processor.stop_requested?
      processor.stop_report
      return true
    end

    if processor.restart_requested?
      processor.restart_report
      return true
    end

    if processor.send_requested?
      processor.send_egotter_requested_report
      return true
    end

    false
  end

  class PeriodicReportProcessor
    include AbstractReportProcessor

    def stop_regexp
      /【?リム(られ)?通知(\s|　)*(停止|ていし)】?/
    end

    def restart_regexp
      /リム(られ)?通知(\s|　)*(再開|さいかい|再会|復活|ふっかつ)/
    end

    def continue_regexp
      /継続|断続|けいぞく|復活|再会/
    end

    def received_regexp
      /リム(られ)?通知(\s|　)*届きました/
    end

    def send_regexp
      /((リム|りむ)(られた?)?通知)|今すぐ(送信)?/
    end

    def stop_report
      user = validate_report_status(@uid)
      return unless user

      DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

      StopPeriodicReportRequest.create(user_id: user.id)
      CreatePeriodicReportStopRequestedMessageWorker.perform_async(user.id)
    end

    def restart_report
      user = validate_report_status(@uid)
      return unless user

      DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

      StopPeriodicReportRequest.find_by(user_id: user.id)&.destroy
      CreatePeriodicReportRestartRequestedMessageWorker.perform_async(user.id)
    end

    def continue_report
      user = validate_report_status(@uid)
      return unless user

      DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

      CreatePeriodicReportContinueRequestedMessageWorker.perform_async(user.id)
    end

    def send_report
      user = validate_report_status(@uid)
      return unless user

      DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

      unless user.has_valid_subscription?
        unless EgotterFollower.exists?(uid: user.uid)
          CreatePeriodicReportNotFollowingMessageWorker.perform_async(user.id)
          return
        end

        if PeriodicReport.interval_too_short?(user)
          CreatePeriodicReportIntervalTooShortMessageWorker.perform_async(user.id)
          return
        end

        if PeriodicReport.access_interval_too_long?(user)
          CreatePeriodicReportAccessIntervalTooLongMessageWorker.perform_async(user.id)
          return
        end
      end

      request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'user')
      CreateUserRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
    end

    def send_egotter_requested_report
      user = validate_report_status(@uid)
      return unless user

      request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'egotter')
      CreateEgotterRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
    end
  end
end
