module Util
  class MessagingUids < OriginalSortedSet
    def self.key
      @@key ||= 'notification_message_worker:messaging_uids'
    end

    def self.ttl
      @@ttl ||= Rails.configuration.x.constants['recently_messaging']
    end
  end
end
