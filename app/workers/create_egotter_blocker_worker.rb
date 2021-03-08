class CreateEgotterBlockerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    1.minute
  end

  # options:
  def perform(uid, options = {})
    EgotterBlocker.create(uid: uid)
  rescue => e
    logger.warn "#{e.inspect} uid=#{uid} options=#{options.inspect}"
  end
end
