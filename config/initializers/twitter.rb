require 'twitter'

module Twitter
  module REST
    class Client
      def follow!(*args)
        super
      ensure
        CallCreateFriendshipCount.new.increment
      end

      def user_timeline(*args)
        super
      ensure
        CallUserTimelineCount.new.increment
      end
    end
  end
end
