class FetchFollowerIdsWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    10.minutes
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(uid, options = {})
    ids = fetch_follower_ids(uid)
    Cache.new.write(uid, ids)
  rescue => e
    handle_worker_error(e, uid: uid, **options)
  end

  private

  def fetch_follower_ids(uid)
    loop_limit = 10
    options = {count: 5000, cursor: -1}
    collection = []

    loop_limit.times do
      client = Bot.api_client.twitter
      response = client.follower_ids(uid, options)&.attrs
      break if response.nil?

      collection << response[:ids]

      break if response[:next_cursor] == 0

      options[:cursor] = response[:next_cursor]
    end

    collection.flatten
  end

  class Cache
    def initialize
      @store = ActiveSupport::Cache::RedisCacheStore.new(
          namespace: "#{Rails.env}:FetchFollowerIdsWorker",
          expires_in: 10.minutes,
          redis: self.class.redis
      )
    end

    def read(uid)
      if (data = @store.read(cache_key(uid)))
        JSON.parse(data)
      end
    end

    def write(uid, data)
      @store.write(cache_key(uid), data.to_json)
    end

    def cache_key(uid)
      "uid:#{uid}"
    end

    def self.redis
      @redis ||= Redis.new(db: 3)
    end
  end
end
