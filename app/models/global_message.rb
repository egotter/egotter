# == Schema Information
#
# Table name: global_messages
#
#  id         :bigint(8)        not null, primary key
#  text       :text(65535)      not null
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_global_messages_on_created_at  (created_at)
#  index_global_messages_on_expires_at  (expires_at)
#
class GlobalMessage < ApplicationRecord
  validates :text, presence: true

  class << self
    def message_found?
      Cache.get
    rescue
      nil
    end

    def current_message
      Cache.get
    rescue
      nil
    end

    def delete_message
      Cache.del
    end
  end

  require 'forwardable'
  require 'singleton'

  class Cache
    include Singleton

    TTL = 2629746 # 1 month

    def initialize
      @key = "#{Rails.env}:GlobalMessage::Cache"
      @redis = RedisClient.new
    end

    def set(value)
      @redis.setex(@key, TTL, value)
    end

    def get
      @redis.get(@key)
    end

    def del
      @redis.del(@key)
    end

    class << self
      extend Forwardable
      def_delegators :instance, :set, :get, :del
    end
  end
end
