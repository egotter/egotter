require 'active_support/concern'

module Concerns::Rescue
  extend ActiveSupport::Concern
  include ActiveSupport::Rescuable

  included do
    attr_accessor :log, :client

    rescue_from 'RuntimeError' do |exception|
      logger.warn "#{self.class}: #{exception.class} #{exception.message}"
      log.update(
        status: false,
        call_count: client.call_count,
        reason: BackgroundSearchLog::SomethingError::MESSAGE,
        message: "#{exception.class} #{exception.message}"
      )
    end

    # ActiveRecord::StatementInvalid Mysql2::Error: Lost connection to MySQL server during query: {SQL}
    # ActiveRecord::StatementInvalid: Mysql2::Error: MySQL server has gone away: {SQL}
    # Mysql2::Error: MySQL server has gone away
    # Twitter::Error::RequestTimeout Net::ReadTimeout
    # Twitter::Error Net::OpenTimeout
    # Twitter::Error Connection reset by peer - SSL_connect
    # Twitter::Error::Forbidden To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.
    # Twitter::Error::Forbidden Your account is suspended and is not permitted to access this feature.
    # Twitter::Error::Forbidden User has been suspended.
    # Twitter::Error::ServiceUnavailable
    # Twitter::Error::ServiceUnavailable Over capacity
    %w(
      ActiveRecord::StatementInvalid
      Mysql2::Error
      Twitter::Error
      Twitter::Error::RequestTimeout
      Twitter::Error::Forbidden
      Twitter::Error::ServiceUnavailable
    ).each do |name|
      rescue_from name do |exception|
        logger.warn "#{self.class}: #{exception.class} #{exception.message}"
        raise exception
      end
    end

    rescue_from 'Twitter::Error::TooManyRequests' do |exception|
      log.update(
        status: false,
        call_count: client.call_count,
        reason: BackgroundSearchLog::TooManyRequests::MESSAGE,
        message: ''
      )
    end

    rescue_from 'Twitter::Error::Unauthorized' do |exception|
      log.update(
        status: false,
        call_count: client.call_count,
        reason: BackgroundSearchLog::Unauthorized::MESSAGE,
        message: ''
      )
    end
  end
end
