class CreateFriendInsightWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    1.minute
  end

  def expire_in
    10.minutes
  end

  # options:
  #   location
  def perform(uid, options = {})
    unless FriendInsight.find_or_initialize_by(uid: uid).fresh?
      FriendInsight.builder(uid).build&.save!
    end
  rescue => e
    Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}", backtrace: e.backtrace
  end
end
