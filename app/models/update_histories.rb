class UpdateHistories

  attr_reader :records

  def initialize(uid, user_id = nil)
    @records =
      if user_id.nil?
        TwitterUser.where(uid: uid).order(created_at: :desc).to_a
      else
        TwitterUser.where(uid: uid, user_id: user_id).order(created_at: :desc).to_a
      end
  end

  def search_count
    records.map { |r| r.search_count }.sum
  end

  def update_count
    records.map { |r| r.update_count }.sum
  end

  def each_cons(num)
    records.each_cons(num)
  end

  def size
    records.size
  end

  def created_at
    records.last.created_at
  end

  def updated_at
    records.first.updated_at
  end
end