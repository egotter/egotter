require 'active_support/concern'

module Concerns::WorkerUtils
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def short_hour(time)
    I18n.l(time, format: :short_hour)
  end

  def _benchmark(message, &block)
    ActiveRecord::Base.benchmark("[benchmark] #{self.class} #{message}", &block)
  end

  def _transaction(message, &block)
    _benchmark(message) { Rails.logger.silence { ActiveRecord::Base.transaction(&block) } }
  end


  def _retry_with_transaction!(message, retry_limit: 1, &block)
    retry_count = 0
    begin
      _transaction(message, &block)
    rescue ActiveRecord::StatementInvalid => e
      if e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        if retry_count < retry_limit
          retry_count += 1
          retry
        else
          @retry_count = retry_count
          raise
        end
      end
    end
  end
end
