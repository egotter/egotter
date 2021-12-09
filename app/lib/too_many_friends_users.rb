# TODO Remove later
class TooManyFriendsUsers < ::Egotter::SortedSet
  def initialize
    super(nil)
    @key = "#{self.class}:any_places:any_ids:#{Rails.env}"
    @ttl = 1.hour.to_i
  end
end
