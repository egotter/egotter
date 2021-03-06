class UpdateCloseFriendsOgImageAclWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(image_id, options = {})
    image_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    1.minute
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(image_id, options = {})
    CloseFriendsOgImage.find(image_id).update_acl
  rescue => e
    logger.warn "#{e.inspect} image_id=#{image_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
