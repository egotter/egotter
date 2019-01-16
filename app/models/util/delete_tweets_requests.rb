module Util
  class DeleteTweetsRequests < OriginalSortedSet
    def self.key
      @@key ||= 'delete_tweets_worker:delete_tweets_uids'
    end

    def self.ttl
      @@ttl ||= Rails.configuration.x.constants['recently_delete_tweets']
    end
  end
end
