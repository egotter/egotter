class UpdateHistories

  attr_reader :records

  def initialize(uid)
    @records = TwitterUser.where(uid: uid).order(created_at: :desc)
  end

  def search_count
    records.sum(:search_count)
  end

  def update_count
    records.sum(:update_count)
  end

  def each_cons(num)
    records.each_cons(num)
  end

  def size
    records.size
  end

  def to_a
    records
  end

  def created_at
    records.last.created_at
  end

  def updated_at
    records.first.updated_at
  end
end