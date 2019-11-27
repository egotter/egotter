class TooManyErrorsUsers < ::Egotter::SortedSet
  def initialize
    super(Redis.client)
    @key = "#{self.class}:user_ids:#{Rails.env}"
    @ttl = 3.days.to_i
  end
end
