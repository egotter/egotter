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
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: CreateFollowerInsightWorker is stopped', uid: uid
      return
    end

    unless FollowerInsight.find_or_initialize_by(uid: uid).fresh?
      FollowerInsight.builder(uid).build&.save!
    end
  rescue => e
    Airbag.exception e, uid: uid, options: options
  end
end
