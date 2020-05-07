class CreatePeriodicReportMessageWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def after_skip(*args)
    logger.warn "The job execution is skipped args=#{args.inspect}"
  end

  # options:
  #   request_id
  #   start_date
  #   end_date
  #   unfriends
  #   unfollowers
  #   interval_too_short
  #   unauthorized
  #   unregistered and uid
  def perform(user_id, options = {})
    options = options.symbolize_keys!

    if options[:unregistered]
      report = PeriodicReport.unregistered_message
      event = report.build_direct_message_event(options[:uid], report.message)
      User.egotter.api_client.create_direct_message_event(event: event)
      return
    end

    user = User.find(user_id)

    if options[:permission_level_not_enough] || !user.notification_setting.enough_permission_level?
      report = PeriodicReport.permission_level_not_enough_message
      event = report.build_direct_message_event(user.uid, report.message)
      User.egotter.api_client.create_direct_message_event(event: event)
      return
    end

    if options[:unauthorized] || !user.authorized?
      report = PeriodicReport.unauthorized_message
      event = report.build_direct_message_event(user.uid, report.message)
      User.egotter.api_client.create_direct_message_event(event: event)
      return
    end

    if options[:interval_too_short]
      PeriodicReport.interval_too_short_message(user_id).deliver!
      return
    end

    if user.credential_token.instance_id.present?
      begin
        push_message = PeriodicReport.periodic_push_message(user.id, **options)
        CreatePushNotificationWorker.perform_async(user.id, '', push_message)
      rescue => e
        logger.warn "#{e.inspect} user_id=#{user_id}"
      end
    end

    PeriodicReport.periodic_message(user_id, **options).deliver!

  rescue => e
    notify_airbrake(e, user_id: user_id, options: options)
    logger.warn "#{e.class} #{e.message} user_id=#{user_id} options=#{options}"
    logger.info e.backtrace.join("\n")
  end
end
