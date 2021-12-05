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
          ['Base', Redis.client],
          ['InMemory', Redis.client(ENV['IN_MEMORY_REDIS_HOST'])],
          ['InMemory(replica)', Redis.client(ENV['IN_MEMORY_REDIS_HOST_REPLICA'])],
          ['ApiCache', ApiClientCacheStore.redis]
      ].map do |name, client|
        "#{name} #{client.used_memory} / #{client.used_memory_peak} / #{client.total_memory}"
      end.join("\n")
    end
  end

  class TwitterApiStat
    def to_s
      follow_limited = GlobalFollowLimitation.new.limited?
      unfollow_limited = GlobalUnfollowLimitation.new.limited?
      [
          "UserTimeline #{CallUserTimelineCount.new.size} (#{TwitterApiLog.where('created_at > ?', 1.day.ago).where(name: 'user_timeline').size})",
          "CreateFriendship(#{follow_limited}) #{CallCreateFriendshipCount.new.size} (400 per user; 1000 per app)",
          "DestroyFriendship(#{unfollow_limited}) #{CallDestroyFriendshipCount.new.size} (800 - 900 per day)",
      ].join("\n")
    end
  end
end
