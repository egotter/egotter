class UpdateHistories

  attr_reader :records

  def initialize(uid)
    @records = TwitterUser.where(uid: uid).order(created_at: :desc).to_a
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