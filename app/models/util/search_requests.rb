module Util
  class SearchRequests < OriginalSortedSet
    def self.key
      @@key ||= 'background_search_worker:searched_uids'
    end

    def self.ttl
      @@ttl ||= Rails.configuration.x.constants['recently_searched']
    end
  end
end
