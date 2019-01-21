module Util
  class TooManyRequestsRequests < OriginalSortedSet
    def self.key
      @@key ||= 'background_search_worker:too_many_requests_user_ids'
    end

    def self.ttl
      @@ttl ||= Rails.configuration.x.constants['recently_too_many_requests']
    end
  end
end
