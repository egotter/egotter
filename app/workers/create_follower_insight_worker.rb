class CreateFollowerInsightWorker
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
    unless FollowerInsight.find_or_initialize_by(uid: uid).fresh?
      FollowerInsight.builder(uid).build&.save!
    end
  rescue => e
    Airbag.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end
end
