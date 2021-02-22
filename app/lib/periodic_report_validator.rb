class PeriodicReportValidator
  def initialize(request)
    @request = request
  end

  def validate_credentials!
    CredentialsValidator.new(@request).validate_and_deliver!
  end

  def validate_following_status!
    FollowingStatusValidator.new(@request).validate_and_deliver!
  end

  def validate_interval!
    IntervalValidator.new(@request).validate_and_deliver!
  end

  def validate_messages_count!
    AllottedMessagesCountValidator.new(@request).validate_and_deliver!
  end

  def validate_web_access!
    WebAccessValidator.new(@request).validate_and_deliver!
  end

  class Validator
    def initialize(request)
      @request = request
    end

    def validate_and_deliver!
      result = validate!

      unless result
        deliver!
      end

      result
    end

    private

    def user_id
      @request.user_id
    end

    def user_or_egotter_requested_job?
      @request.worker_context == CreateUserRequestedPeriodicReportWorker ||
          @request.worker_context == CreateEgotterRequestedPeriodicReportWorker
    end

    def logger
      Rails.logger
    end
  end

  class CredentialsValidator < Validator
    def validate!
      @request.user.api_client.verify_credentials
      true
    rescue => e
      logger.info "#{self.class}##{__method__} #{e.inspect} request=#{@request.inspect}"
      @request.update(status: 'unauthorized')

      false
    end

    def deliver!
      if user_or_egotter_requested_job?
        jid = CreatePeriodicReportUnauthorizedMessageWorker.perform_async(user_id)
        @request.update(status: 'unauthorized,message_skipped') unless jid
      end
    end
  end

  class IntervalValidator < Validator
    def validate!
      if CreatePeriodicReportRequest.interval_too_short?(include_user_id: user_id, reject_id: @request.id)
        @request.update(status: 'interval_too_short')

        false
      else
        true
      end
    end

    def deliver!
      if user_or_egotter_requested_job?
        CreatePeriodicReportIntervalTooShortMessageWorker.perform_async(user_id)
      end
    end
  end

  class FollowingStatusValidator < Validator
    def validate!
      user = @request.user
      return true if EgotterFollower.exists?(uid: user.uid)
      return true if user.api_client.twitter.friendship?(user.uid, User::EGOTTER_UID)

      @request.update(status: 'not_following')

      false
    rescue => e
      logger.info "#{self.class}##{__method__} #{e.inspect} request=#{@request.inspect}"
      true
    end

    def deliver!
      if user_or_egotter_requested_job?
        jid = CreatePeriodicReportNotFollowingMessageWorker.perform_async(@request.user_id)
        @request.update(status: 'not_following,message_skipped') unless jid
      end
    end
  end

  class AllottedMessagesCountValidator < Validator
    def validate!
      user = @request.user
      return true unless PeriodicReport.messages_allotted?(user)

      if PeriodicReport.allotted_messages_left?(user, count: 3)
        true
      else
        @request.update(status: 'soft_limited')
        false
      end
    end

    def deliver!
      jid = CreatePeriodicReportAllottedMessagesNotEnoughMessageWorker.perform_async(user_id)
      @request.update(status: 'soft_limited,message_skipped') unless jid
    end
  end

  class WebAccessValidator < Validator
    def validate!
      user = @request.user
      if PeriodicReport.access_interval_too_long?(user)
        @request.update(status: 'too_little_access')
        false
      else
        true
      end
    end

    def deliver!
      jid = CreatePeriodicReportAccessIntervalTooLongMessageWorker.perform_async(user_id)
      @request.update(status: 'too_little_access,message_skipped') unless jid
    end
  end
end
