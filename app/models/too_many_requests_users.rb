class TooManyRequestsUsers < ::Egotter::SortedSet
  def initialize
    super(Redis.client)
    @key = "#{self.class}:any_places:any_ids:#{Rails.env}"
    @ttl = 15.minutes.to_i
  end
end
