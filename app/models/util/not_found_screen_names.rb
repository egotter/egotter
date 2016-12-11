module Util
  class NotFoundScreenNames < OriginalSortedSet
    def self.key
      @@key ||= 'background_search_worker:not_found_screen_names'
    end

    def self.ttl
      @@ttl ||= 60.minutes
    end
  end
end
