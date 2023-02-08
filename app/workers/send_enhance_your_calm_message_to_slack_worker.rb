class SendEnhanceYourCalmMessageToSlackWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(args, options = {})
    counter = Counter.new
    counter.increment
    if counter.value < 10
      SlackBotClient.channel(:monit_eyc).post_message(args.inspect)
    end
  rescue => e
    Airbag.exception e
  end

  class Counter
    def initialize
      @key = 'SendEnhanceYourCalmMessageToSlackWorker::Counter'
      @redis = self.class.redis
    end

    def value
      @redis.get(key)&.to_i || 0
    end

    def increment
      k = key
      @redis.multi do |r|
        r.incr(k)
        r.expire(k, 70)
      end
    end

    def key
      time = Time.zone.now.strftime('%Y/%m/%d %H:%M')
      "#{@key}:#{time}"
    end

    LOCK = Mutex.new

    class << self
      def redis
        LOCK.synchronize do
          @redis ||= RedisClient.new
        end
      end
    end
  end
end
