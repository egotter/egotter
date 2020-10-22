class GlobalActiveSendDirectMessageFromEgotterCount < ::Egotter::AsyncSortedSet

  def initialize
    super(nil)

    @ttl = 1.day
    @key = "#{Rails.env}:#{self.class}:#{@ttl}:any_ids"
  end

  def increment
    add(Time.zone.now.to_f)
  end
end
