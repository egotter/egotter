class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(uids, options = {})
    Digest::MD5.hexdigest(uids.to_s)
  end

  def unique_in
    10.minutes
  end

  # options:
  #   compressed
  #   force_update
  #   user_id
  #   enqueued_by
  def perform(uids, options = {})
    if options['compressed']
      uids = decompress(uids)
    end

    client = (options['user_id'] && options['user_id'] != -1) ? User.find(options['user_id']).api_client : Bot.api_client
    do_perform(uids, client, options['force_update'], options['user_id'], enqueued_by: options[:enqueued_by])

  rescue => e
    # Errno::EEXIST File exists @ dir_s_mkdir
    # Errno::ENOENT No such file or directory @ rb_sysopen
    logger.warn "#{e.class} #{e.message} #{uids.inspect.truncate(150)} #{options.inspect}"
    logger.info e.backtrace.join("\n")
  end

  def do_perform(uids, client, force_update, user_id, enqueued_by:)
    tries ||= 2
    TwitterDB::User::Batch.fetch_and_import!(uids.map(&:to_i), client: client, force_update: force_update)
  rescue => e
    if e.message == 'Invalid or expired token.' && user_id && (tries -= 1) > 0
      client = Bot.api_client
      logger.warn "Retry with a bot client #{user_id} #{enqueued_by}"
      retry
    elsif e.message.include?('Connection reset by peer')
      retry
    else
      raise
    end
  end

  class << self
    def compress(uids)
      Base64.encode64(Zlib::Deflate.deflate(uids.join(',')))
    end
  end

  def decompress(data)
    Zlib::Inflate.inflate(Base64.decode64(data)).split(',').map(&:to_i)
  end
end
