require 'active_support/concern'

module ConnectionChecker
  extend ActiveSupport::Concern

  included do
    before_action :check_database_connection
    before_action :check_redis_connection
  end

  def check_database_connection
    ActiveRecord::Base.connection.execute('select 1')
  rescue => e
    redirect_to error_pages_database_error_path(via: current_via)
  end

  def check_redis_connection
    RedisClient.new.ping
  rescue => e
    redirect_to error_pages_redis_error_path(via: current_via)
  end
end
