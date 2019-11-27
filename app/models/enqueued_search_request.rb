class EnqueuedSearchRequest < ::Egotter::SortedSet
  def initialize
    super(Redis.client)

    @ttl = 10.minutes.to_i
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end
end
