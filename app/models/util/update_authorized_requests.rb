module Util
  class UpdateAuthorizedRequests < OriginalSortedSet
    def self.key
      @@key ||= 'update_authorized:uids'
    end

    def self.ttl
      @@ttl ||= (Rails.env.production? ? 1.hour : 10.minutes)
    end
  end
end
