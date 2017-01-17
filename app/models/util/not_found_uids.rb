module Util
  class NotFoundUids < OriginalSortedSet
    def self.key
      @@key ||= 'background_search_worker:not_found_uids'
    end

    def self.ttl
      @@ttl ||= 60.minutes
    end
  end
end
