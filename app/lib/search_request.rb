require 'forwardable'
require 'singleton'

class SearchRequest
  include Singleton

  def initialize
    @store = ActiveSupport::Cache::RedisCacheStore.new(
        namespace: "#{Rails.env}:search_request",
        expires_in: 10.minutes,
        redis: RedisClient.new
    )
  end

  def exists?(screen_name)
    @store.exist?(screen_name)
  end

  def write(screen_name)
    @store.write(screen_name, true)
  end

  class << self
    extend Forwardable
    def_delegators :instance, :exists?, :write
  end
end
