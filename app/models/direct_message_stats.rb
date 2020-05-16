class DirectMessageStats
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
