class PeriodicReportResponder < AbstractMessageResponder

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
      elsif @text.match?(continue_regexp)
        @continue = true
      elsif @text.match?(received_regexp)
        @received = true
      elsif @text.match?(send_regexp)
        @send = true
      elsif @text.match?(help_regexp)
        @help = true
      end

      @stop || @restart || @continue || @received || @send || @help
    end

    def stop_regexp
      /(リムーブ|リムられ|リム|りむ)(通知)?(\s|　)*停止/
    end

    def restart_regexp
      /(リムーブ|リムられ|リム|りむ)(通知)?(\s|　)*再開/
    end

    def continue_regexp
      /(リムーブ|リムられ|リム|りむ)(通知)?(\s|　)*継続/
    end

    def received_regexp
      /(リムーブ|リムられ|リム|りむ)(通知)?(\s|　)*(届きました|届いた)/
    end

    def send_regexp
      /(リムーブ|リムられ|リム|りむ)(通知)?(\s|　)*(今すぐ)?送信/
    end

    def help_regexp
      /リムーブ|りむーぶ|リムられ|りむられ|(^(リム通?|通知|再開|継続|送信|停止|止めて|今すぐ(送信)?|DM|使い方)$)/
    end

    def send_message
      user = validate_report_status(@uid)
      return unless user

      if @stop || @restart || @continue || @received || @send || @help
        DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)
      end

      if @stop
        StopPeriodicReportRequest.create(user_id: user.id)
        CreatePeriodicReportStopRequestedMessageWorker.perform_async(user.id)
      elsif @restart
        StopPeriodicReportRequest.find_by(user_id: user.id)&.destroy
        CreatePeriodicReportRestartRequestedMessageWorker.perform_async(user.id)
      elsif @continue
        CreatePeriodicReportContinueRequestedMessageWorker.perform_async(user.id)
      elsif @received
        CreatePeriodicReportReceivedMessageWorker.perform_async(@uid)
      elsif @send
        send_periodic_report(user)
      elsif @help
        CreatePeriodicReportHelpMessageWorker.perform_async(user.id)
      end
    end

    def send_periodic_report(user)
      unless user.has_valid_subscription?
        # TODO Check User#send_periodic_report_even_though_not_following?
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
  end
end
