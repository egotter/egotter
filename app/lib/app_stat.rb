class AppStat
  def to_s
    [
        DirectMessageStat.new,
        RedisStat.new,
        TwitterApiStat.new,
        "PersonalityInsight #{CallPersonalityInsightCount.new.size}",
    ].join("\n\n")
  end

  class DirectMessageStat
    def to_s
      dm_count = {
          total: Ahoy::Event.total_dm.where('time > ?', 1.day.ago).size,
          active: Ahoy::Event.active_dm.where('time > ?', 1.day.ago).size,
          passive: Ahoy::Event.passive_dm.where('time > ?', 1.day.ago).size,
      }

      dm_from_egotter = {
          total: Ahoy::Event.dm_from_egotter.where('time > ?', 1.day.ago).size,
          active: Ahoy::Event.active_dm_from_egotter.where('time > ?', 1.day.ago).size,
          passive: Ahoy::Event.passive_dm_from_egotter.where('time > ?', 1.day.ago).size,
      }

      [
          "DirectMessageSentFlag #{GlobalDirectMessageSentFlag.new.size}",
          "DirectMessageReceivedFlag #{GlobalDirectMessageReceivedFlag.new.size}",
          "SendDirectMessageCount #{dm_count[:total]} (active #{dm_count[:active]} passive #{dm_count[:passive]})",
          "SendDirectMessageFromEgotterCount #{dm_from_egotter[:total]} (active #{dm_from_egotter[:active]} passive #{dm_from_egotter[:passive]})",
      ].join("\n")
    end
  end

  class RedisStat
    def to_s
      [
          ['Base', RedisClient.new],
          ['InMemory', RedisClient.new(host: ENV['IN_MEMORY_REDIS_HOST'])],
          ['ApiCache', ApiClientCacheStore.instance.redis]
      ].map do |name, client|
        info = client.info rescue {}
        "#{name} used=#{info['used_memory_rss_human']} peak=#{info['used_memory_peak_human']} total=#{info['total_system_memory_human']}"
      end.join("\n")
    end
  end

  class TwitterApiStat
    def to_s
      timeline_count = TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'user_timeline').size
      follow_count = TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'follow!').size
      unfollow_count = TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'unfollow').size

      [
          "user_timeline #{timeline_count}",
          "follow! #{follow_count} (400 per user; 1000 per app)",
          "unfollow #{unfollow_count} (800 - 900 per day)",
      ].join("\n")
    end
  end
end
