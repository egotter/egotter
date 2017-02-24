module Util
  class CreatingUids < OriginalSortedSet
    def self.key
      @@key ||= 'background_search_worker:creating_uids'
    end

    def self.ttl
      @@ttl ||= Rails.configuration.x.constants['recently_creating']
    end
  end
end
