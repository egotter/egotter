require 'twitter'

# It is necessary to load the classes first because they may be called in Thread.
require_relative '../../app/models/call_create_friendship_count'
require_relative '../../app/models/call_user_timeline_count'
require_relative '../../app/models/call_create_direct_message_event_count'

module Egotter
  module Twitter
    module Measurement
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

      def create_direct_message_event(*args)
        if !GlobalDirectMessageReceivedFlag.new.exists?(dig_recipient_uid(args)) &&
            GlobalDirectMessageLimitation.new.limited?
          raise ::Twitter::Error::EnhanceYourCalm.new('Already raised')
        end

        result = nil
        begin
          result = super
        rescue ::Twitter::Error::EnhanceYourCalm => e
          GlobalDirectMessageLimitation.new.limit_start
          raise
        else
          CallCreateDirectMessageEventCount.new.increment
        end

        result
      end

      def dig_recipient_uid(args)
        if args.length == 1 && args.last.is_a?(Hash)
          args.last.dig(:event, :message_create, :target, :recipient_id)
        else
          nil
        end
      end
    end
  end
end

::Twitter::REST::Client.prepend(::Egotter::Twitter::Measurement)
