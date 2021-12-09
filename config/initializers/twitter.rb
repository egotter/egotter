require 'twitter'

module Egotter
  module Twitter
    module Measurement
      def follow!(*args)
        super
      ensure
        CreateTwitterApiLogWorker.perform_async(name: __method__)
      end

      def unfollow(*args)
        super
      ensure
        CreateTwitterApiLogWorker.perform_async(name: __method__)
      end

      def user_timeline(*args)
        super
      ensure
        CreateTwitterApiLogWorker.perform_async(name: __method__)
      end

      def create_direct_message_event(*args)
        recipient_uid = dig_recipient_uid(args)

        if !DirectMessageReceiveLog.message_received?(recipient_uid) && DirectMessageLimitedFlag.on?
          message_text = dig_message_text(args).inspect.truncate(100)
          error_message = "Sending DMs is rate-limited remaining=#{DirectMessageLimitedFlag.remaining} text=#{message_text}"
          raise ::Twitter::Error::EnhanceYourCalm.new(error_message)
        end

        result = nil
        begin
          result = super
        rescue ::Twitter::Error::EnhanceYourCalm => e
          DirectMessageLimitedFlag.on
          raise
        end

        result
      end

      def dig_recipient_uid(args)
        if args.length == 1 && args.last.is_a?(Hash)
          args.last.dig(:event, :message_create, :target, :recipient_id)
        elsif args.length == 2 && args.first.is_a?(Integer)
          args.first
        else
          nil
        end
      rescue => e
        nil
      end

      def dig_message_text(args)
        if args.length == 1 && args.last.is_a?(Hash)
          args.last.dig(:event, :message_create, :message_data, :text)
        elsif args.length == 2 && args.second.is_a?(String)
          args.second
        else
          nil
        end
      rescue => e
        nil
      end
    end
  end
end

::Twitter::REST::Client.prepend(::Egotter::Twitter::Measurement)
