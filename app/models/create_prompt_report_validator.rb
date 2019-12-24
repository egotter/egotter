class CreatePromptReportValidator
  attr_reader :user, :request

  def initialize(request:)
    @request = request
    @user = request.user
  end

  def validate!
    raise CreatePromptReportRequest::Unauthorized unless credentials_verified?
    raise CreatePromptReportRequest::TooManyErrors if too_many_errors?
    raise CreatePromptReportRequest::PermissionLevelNotEnough unless user.notification_setting.enough_permission_level?
    raise CreatePromptReportRequest::TooShortRequestInterval if too_short_request_interval?
    raise CreatePromptReportRequest::Unauthorized unless user.authorized?
    raise CreatePromptReportRequest::ReportDisabled unless user.notification_setting.dm_enabled?
    raise CreatePromptReportRequest::TooShortSendInterval unless user.notification_setting.prompt_report_interval_ok?
    raise CreatePromptReportRequest::UserSuspended if suspended?
    raise CreatePromptReportRequest::TooManyFriends if SearchLimitation.limited?(fetch_user, signed_in: true)
    raise CreatePromptReportRequest::EgotterBlocked if blocked?

    if TwitterUser.exists?(uid: user.uid)
      twitter_user = TwitterUser.latest_by(uid: user.uid)
      raise CreatePromptReportRequest::TooManyFriends if SearchLimitation.limited?(twitter_user, signed_in: true)
      raise CreatePromptReportRequest::MaybeImportBatchFailed if twitter_user.no_need_to_import_friendships?
    end

    raise CreatePromptReportRequest::UserInactive unless user.active_access?(CreatePromptReportRequest::ACTIVE_DAYS)
  end

  def credentials_verified?
    ApiClient.do_request_with_retry(client.twitter, :verify_credentials, [])
  rescue => e
    if AccountStatus.unauthorized?(e)
      false
    else
      raise CreatePromptReportRequest::Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  end

  # Notice: If the InitializationStarted occurs three times,
  # you will not be able to send a message.
  def too_many_errors?
    errors = CreatePromptReportLog.recent_error_logs(user_id: user.id, request_id: request.id).pluck(:error_class)

    meet_requirements_for_too_many_errors?(errors).tap do |val|
      # Save this value in Redis since it is difficult to retrieve this value efficiently with SQL.
      if val
        (@too_many_errors_users ||= TooManyErrorsUsers.new).add(user.id) # The ivar is used for testing
      end
    end
  end

  def meet_requirements_for_too_many_errors?(errors)
    errors.size == CreatePromptReportRequest::TOO_MANY_ERRORS_SIZE && errors.all? { |err| err.present? }
  end

  def too_short_request_interval?
    CreatePromptReportRequest.where(user_id: user.id).
        where.not(id: request.id).
        interval_ng_user_ids.
        any?
  end

  def suspended?
    fetch_user[:suspended]
  end

  def blocked?
    if BlockedUser.exists?(uid: fetch_user[:id])
      true
    else
      blocked = client.blocked_ids.include? User::EGOTTER_UID
      CreateBlockedUserWorker.perform_async(fetch_user[:id], fetch_user[:screen_name]) if blocked
      blocked
    end
  rescue => e
    if AccountStatus.temporarily_locked?(e)
      raise CreatePromptReportRequest::TemporarilyLocked.new("#{__method__}: #{e.class} #{e.message}")
    else
      raise CreatePromptReportRequest::Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  end

  def fetch_user
    @fetch_user ||= client.user(user.uid)
  rescue => e
    if AccountStatus.unauthorized?(e)
      raise CreatePromptReportRequest::Unauthorized
    elsif AccountStatus.temporarily_locked?(e)
      raise CreatePromptReportRequest::TemporarilyLocked.new("#{__method__}: #{e.class} #{e.message}")
    else
      raise CreatePromptReportRequest::Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  end

  def client
    @client ||= user.api_client
  end
end
