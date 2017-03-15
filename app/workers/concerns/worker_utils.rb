require 'active_support/concern'

module Concerns::WorkerUtils
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  UNAUTHORIZED_MESSAGES = [
    'Invalid or expired token.',
    "You have been blocked from viewing this user's profile.",
    'Could not authenticate you.',
    'Not authorized.'
  ]

  FORBIDDEN_MESSAGES = [
    'User has been suspended.',
    'Your account is suspended and is not permitted to access this feature.',
    "You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>.",
    'To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'
  ]

  NOT_FOUND_MESSAGES = [
    'User not found.',
    'No user matches for specified terms.'
  ]

  def short_hour(time)
    time.nil? ? '' : I18n.l(time, format: :short_hour)
  end

  def _benchmark(message, &block)
    ActiveRecord::Base.benchmark("[benchmark] #{self.class} #{message}", &block)
  end

  def _transaction(message, &block)
    _benchmark(message) { Rails.logger.silence { ActiveRecord::Base.transaction(&block) } }
  end

  RETRY_TIMEOUT = 10.seconds

  def _retry_with_transaction!(message, retry_limit: 1, retry_timeout: RETRY_TIMEOUT, &block)
    retry_count = 0
    start_time = Time.zone.now

    begin
      _transaction(message, &block)
    rescue ActiveRecord::StatementInvalid => e
      wait_seconds = Time.zone.now - start_time
      if e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        if retry_count >= retry_limit || wait_seconds > retry_timeout
          @retry_count = retry_count
          @wait_seconds = wait_seconds.round(1)
          raise
        end

        sleep(rand)
        retry_count += 1
        retry
      end
    end
  end
end
