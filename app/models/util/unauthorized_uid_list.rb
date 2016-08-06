module Util
  class UnauthorizedUidList < UidList
    def self.key
      @@key ||= 'background_update_worker:unauthorized'
    end

    def self.ttl
      @@ttl ||= 10.years.to_i
    end
  end
end