class UpdateHistories
  attr_reader :records

  def initialize(uid)
    @records = TwitterUser.includes(:twitter_db_user).where(uid: uid).order(created_at: :desc)
  end

  def size
    records.size
  end

  def created_at
    records.last&.created_at
  end

  def updated_at
    records.first&.updated_at
  end
end