module Egotter
  class TooManyErrorsUsers < ::Egotter::SortedSet
    def initialize
      super(Redis.client)
      @key = "#{self.class}:user_ids"
      @ttl = 3.days.to_i
    end
  end
end
