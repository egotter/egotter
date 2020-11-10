require 'digest/md5'

class CreatePeriodicReportMessageWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    picked_id = user_id || "uid-#{options[:uid] || options['uid']}"
    "#{picked_id}-#{Digest::MD5.hexdigest(options.inspect)}"
  end

  UNIQUE_IN = 3.seconds

  def unique_in
    UNIQUE_IN
  end

  def after_skip(*args)
    logger.warn "The job of #{self.class} is skipped args=#{args.inspect}"
  end

  def _timeout_in
    30.seconds
  end

  # options:
  #   version
  #   request_id
  #   start_date
  #   end_date
  #   friends_count
  #   followers_count
  #   unfriends
  #   unfollowers
  #   account_statuses
  #   new_friends
  #   new_followers
  #   worker_context
  #
  #   interval_too_short
  #   unauthorized
  #   unregistered and uid
  #   stop_requested
  #   restart_requested
  #   not_following
  #   request_interval_too_short
  #   sending_soft_limited
  #   web_access_hard_limited
  #   scheduled_job_exists and scheduled_jid
  #   scheduled_job_created and scheduled_jid
  #   allotted_messages_will_expire
  def perform(user_id, options = {})
    options = options.symbolize_keys!

    if options[:unregistered]
      perform_unregistered(options[:uid])
      return
    end

    user = User.find(user_id)

    # TODO Remove later
    if options[:restart_requested]
      CreatePeriodicReportRestartRequestedMessageWorker.perform_async(user_id)
      return
    end

    # TODO Remove later
    if options[:stop_requested]
      CreatePeriodicReportStopRequestedMessageWorker.perform_async(user_id)
      return
    end

    # TODO Remove later
    if options[:not_following]
      CreatePeriodicReportNotFollowingMessageWorker.perform_async(user_id)
      return
    end

    if options[:permission_level_not_enough] || !user.notification_setting.enough_permission_level?
      perform_permission_level_not_enough(user)
      return
    end

    if options[:unauthorized] || !user.authorized?
      perform_unauthorized(user)
      return
    end

    # TODO Remove later
    if options[:request_interval_too_short]
      CreatePeriodicReportRequestIntervalTooShortMessageWorker.perform_async(user_id)
      return
    end

    # TODO Remove later
    if options[:interval_too_short]
      CreatePeriodicReportIntervalTooShortMessageWorker.perform_async(user_id)
      return
    end

    # TODO Remove later
    if options[:scheduled_job_created]
      handle_weird_error(user) do
        PeriodicReport.scheduled_job_created_message(user_id, options[:scheduled_jid]).deliver!
      end
      return
    end

    # TODO Remove later
    if options[:sending_soft_limited]
      CreatePeriodicReportAllottedMessagesNotEnoughMessageWorker.perform_async(user_id)
      return
    end

    # TODO Remove later
    if options[:web_access_hard_limited]
      CreatePeriodicReportAccessIntervalTooLongMessageWorker.perform_async(user_id)
      return
    end

    # TODO Remove later
    if options[:allotted_messages_will_expire]
      CreatePeriodicReportAllottedMessagesWillExpireMessageWorker.perform_async(user_id)
      return
    end

    if user.credential_token.instance_id.present?
      begin
        push_message = PeriodicReport.periodic_push_message(user.id, options)
        CreatePushNotificationWorker.perform_async(user.id, '', push_message, request_id: options[:request_id])
      rescue => e
        logger.warn "I can't send a push-notification #{e.inspect} user_id=#{user_id} request_id=#{options[:request_id]}"
      end
    end

    handle_weird_error(user) do
      PeriodicReport.periodic_message(user_id, options).deliver!
    end

  rescue => e
    if not_fatal_error?(e)
      logger.info "#{e.class} #{e.message} user_id=#{user_id} options=#{options}"
    else
      logger.warn "#{e.class} #{e.message} user_id=#{user_id} options=#{options}"
      logger.info e.backtrace.join("\n")
    end
  end

  def perform_unregistered(uid)
    send_message_from_egotter(uid, PeriodicReport.unregistered_message.message)
  end

  def perform_permission_level_not_enough(user)
    send_message_from_egotter(user.uid, PeriodicReport.permission_level_not_enough_message.message)
  end

  def perform_unauthorized(user)
    send_message_from_egotter(user.uid, PeriodicReport.unauthorized_message.message)
  end

  def send_message_from_egotter(uid, message, options = {})
    event = PeriodicReport.build_direct_message_event(uid, message, options)
    User.egotter.api_client.create_direct_message_event(event: event)
  end

  def handle_weird_error(user)
    yield
  rescue => e
    if weird_error?(e, user)
      logger.info { "#{__method__} #{e.inspect} user_id=#{user.id}" }
      send_message_from_egotter(user.uid, PeriodicReport.cannot_send_messages_message.message)
    else
      raise
    end
  end

  def weird_error?(e, user)
    DirectMessageStatus.cannot_send_messages?(e) && PeriodicReport.messages_allotted?(user)
  end

  def not_fatal_error?(e)
    DirectMessageStatus.you_have_blocked?(e) ||
        DirectMessageStatus.not_following_you?(e) ||
        DirectMessageStatus.cannot_find_specified_user?(e) ||
        DirectMessageStatus.protect_out_users_from_spam?(e) ||
        DirectMessageStatus.your_account_suspended?(e) ||
        DirectMessageStatus.cannot_send_messages?(e) ||
        DirectMessageStatus.might_be_automated?(e) ||
        TwitterApiStatus.invalid_or_expired_token?(e)
  end
end
