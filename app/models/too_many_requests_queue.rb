class TooManyRequestsQueue < Util::OriginalSortedSet
  def initialize
    super(Redis.client)
    @key = "#{self.class}:any_places:any_ids:#{Rails.env}"
    @ttl = 15.minutes
  end
end
