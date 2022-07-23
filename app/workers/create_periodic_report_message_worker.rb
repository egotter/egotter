require 'digest/md5'

class CreatePeriodicReportMessageWorker
  include Sidekiq::Worker
  include ReportErrorHandler
  include ReportRetryHandler
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
    Airbag.warn "The job of #{self.class} is skipped args=#{args.inspect}"
  end

  def timeout_in
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

    unless options[:periodic_report_id]
      Airbag.warn "options[:periodic_report_id] is not passed user_id=#{user_id} options=#{options}"
      return
    end

    user = User.find(user_id)

    if PeriodicReport.send_report_limited?(user.uid)
      retry_current_report(user.id, options)
      return
    end

    send_push_message(user, options)
    send_direct_message(user, options)
  rescue => e
    Airbag.exception e, user_id: user_id, options: options
  end

  def send_push_message(user, options)
    return unless user.credential_token.instance_id.present?

    message = PeriodicReport.periodic_push_message(user.id, options)
    CreatePushNotificationWorker.perform_async(user.id, '', message, request_id: options[:request_id])
  rescue => e
    Airbag.warn "I can't send a push-notification #{e.inspect} user_id=#{user.id} request_id=#{options[:request_id]}"
  end

  def send_direct_message(user, options)
    PeriodicReport.periodic_message(user.id, options).deliver!
  rescue => e
    if DirectMessageStatus.enhance_your_calm?(e)
      retry_current_report(user.id, options)
    elsif ignorable_report_error?(e)
      Airbag.info "#{e.class} #{e.message} user_id=#{user.id} options=#{options}"
    else
      raise
    end
  end
end
