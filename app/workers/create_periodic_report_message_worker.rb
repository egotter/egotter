require 'digest/md5'

class CreatePeriodicReportMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
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
  def perform(user_id, options = {})
    options = options.symbolize_keys!
    user = User.find(user_id)

    if PeriodicReport.send_report_limited?(user.uid)
      retry_current_job(user.id, options)
      return
    end

    send_push_message(user, options)
    send_direct_message(user, options)
  rescue => e
    logger.warn "#{e.class} #{e.message} user_id=#{user_id} options=#{options}"
    logger.info e.backtrace.join("\n")
  end

  def send_push_message(user, options)
    return unless user.credential_token.instance_id.present?

    message = PeriodicReport.periodic_push_message(user.id, options)
    CreatePushNotificationWorker.perform_async(user.id, '', message, request_id: options[:request_id])
  rescue => e
    logger.warn "I can't send a push-notification #{e.inspect} user_id=#{user.id} request_id=#{options[:request_id]}"
  end

  def send_direct_message(user, options)
    handle_weird_error(user) do
      PeriodicReport.periodic_message(user.id, options).deliver!
    end
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_job(user.id, options, exception: e)
    elsif ignorable_report_error?(e)
      logger.info "#{e.class} #{e.message} user_id=#{user.id} options=#{options}"
    else
      raise
    end
  end

  def retry_current_job(user_id, options, exception: nil)
    logger.add(exception ? Logger::WARN : Logger::INFO) { "#{self.class} will be performed again user_id=#{user_id} exception=#{exception.inspect}" }
    CreatePeriodicReportMessageWorker.perform_in(1.hour + rand(30).minutes, user_id, options)
  end

  def send_message_from_egotter(uid, message, options = {})
    event = PeriodicReport.build_direct_message_event(uid, message, options)
    User.egotter.api_client.create_direct_message_event(event: event)
  end

  # TODO Remove later
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
end
