class SearchLimitationSoftLimitedUsers < ::Egotter::SortedSet
  def initialize
    super(Redis.client)
    @key = "#{self.class}:any_places:any_ids:#{Rails.env}"
    @ttl = 10.seconds.to_i
  end
end
