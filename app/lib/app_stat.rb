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
    def initialize
      @stats = [
          GlobalTotalDirectMessageSentFlag,
          GlobalTotalDirectMessageReceivedFlag,
          GlobalDirectMessageSentFlag,
          GlobalDirectMessageReceivedFlag,
          GlobalSendDirectMessageCount,
          GlobalActiveSendDirectMessageCount,
          GlobalPassiveSendDirectMessageCount,
          GlobalSendDirectMessageFromEgotterCount,
          GlobalActiveSendDirectMessageFromEgotterCount,
          GlobalPassiveSendDirectMessageFromEgotterCount
      ].map { |klass| [klass, klass.new.size] }
    end

    def to_s
      @stats.map do |name, value|
        "#{name} #{value}"
      end.join("\n")
    end
  end

  class RedisStat
    def initialize
      @stats = [
          ['Base', Redis.client],
          ['InMemory', InMemory],
          ['ApiCache', ApiClient::CacheStore.redis_client]
      ].map { |name, obj| [name, "#{obj.used_memory} / #{obj.used_memory_peak}"] }
    end

    def to_s
      @stats.map do |name, value|
        "#{name} #{value}"
      end.join("\n")
    end
  end

  class TwitterApiStat
    def to_s
      [
          "UserTimeline #{CallUserTimelineCount.new.size}",
          "CreateFriendship #{CallCreateFriendshipCount.new.size}",
          "DestroyFriendship #{CallDestroyFriendshipCount.new.size}",
      ].join("\n")
    end
  end
end
