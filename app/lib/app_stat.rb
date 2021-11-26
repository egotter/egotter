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
      [
          "TotalDirectMessageSentFlag #{GlobalTotalDirectMessageSentFlag.new.size}",
          "TotalDirectMessageReceivedFlag #{GlobalTotalDirectMessageReceivedFlag.new.size}",
          "DirectMessageSentFlag #{GlobalDirectMessageSentFlag.new.size}",
          "DirectMessageReceivedFlag #{GlobalDirectMessageReceivedFlag.new.size}",
          "SendDirectMessageCount #{GlobalSendDirectMessageCount.new.size} (#{Ahoy::Event.total_dm.where('time > ?', 1.day.ago).size})",
          "ActiveSendDirectMessageCount #{GlobalActiveSendDirectMessageCount.new.size} (#{Ahoy::Event.active_dm.where('time > ?', 1.day.ago).size})",
          "PassiveSendDirectMessageCount #{GlobalPassiveSendDirectMessageCount.new.size} (#{Ahoy::Event.passive_dm.where('time > ?', 1.day.ago).size})",
          "SendDirectMessageFromEgotterCount #{GlobalSendDirectMessageFromEgotterCount.new.size} (#{Ahoy::Event.dm_from_egotter.where('time > ?', 1.day.ago).size})",
          "ActiveSendDirectMessageFromEgotterCount #{GlobalActiveSendDirectMessageFromEgotterCount.new.size} (#{Ahoy::Event.active_dm_from_egotter.where('time > ?', 1.day.ago).size})",
          "PassiveSendDirectMessageFromEgotterCount #{GlobalPassiveSendDirectMessageFromEgotterCount.new.size} (#{Ahoy::Event.passive_dm_from_egotter.where('time > ?', 1.day.ago).size})",
      ].join("\n")
    end
  end

  class RedisStat
    def to_s
      [
          ['Base', Redis.client],
          ['InMemory', InMemory.redis_instance],
          ['ApiCache', ApiClientCacheStore.redis_client]
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
          "UserTimeline #{CallUserTimelineCount.new.size}",
          "CreateFriendship(#{follow_limited}) #{CallCreateFriendshipCount.new.size} (400 per user; 1000 per app)",
          "DestroyFriendship(#{unfollow_limited}) #{CallDestroyFriendshipCount.new.size} (800 - 900 per day)",
      ].join("\n")
    end
  end
end
