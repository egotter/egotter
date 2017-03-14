require 'active_support/concern'

module Concerns::WorkerUtils
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

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
      if e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        if retry_count >= retry_limit || (Time.zone.now - start_time > retry_timeout)
          @retry_count = retry_count
          raise
        end

        sleep(rand)
        retry_count += 1
        retry
      end
    end
  end
end
