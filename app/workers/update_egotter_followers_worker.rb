class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.minutes
  end

  def _timeout_in
    3.minute
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(options = {})
    uids = EgotterFollower.collect_uids
    EgotterFollower.import_uids(uids)
    uids = EgotterFollower.filter_unnecessary_uids(uids)
    EgotterFollower.delete_uids(uids)
  rescue => e
    logger.warn "#{e.class}: #{e.message.truncate(200)} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
