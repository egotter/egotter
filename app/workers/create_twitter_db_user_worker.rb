require 'digest/md5'

class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
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

    client = pick_client(options)
    @retries = 2

    begin
      TwitterDB::User::Batch.fetch_and_import!(uids, client: client, force_update: options['force_update'])
    rescue => e
      unless AccountStatus.unauthorized?(e)
        logger.warn "Retry with a bot client #{options.inspect} #{e.inspect}"
      end

      if meet_requirements_for_retrying?(e) && @retries > 0
        client = Bot.api_client
        @retries -= 1
        retry
      else
        raise
      end
    end

  rescue => e
    # Errno::EEXIST File exists @ dir_s_mkdir
    # Errno::ENOENT No such file or directory @ rb_sysopen
    logger.warn "#{e.class} #{e.message} #{uids.inspect.truncate(150)} #{options.inspect}"
    notify_airbrake(e)
  end

  def meet_requirements_for_retrying?(ex)
    AccountStatus.unauthorized?(ex) ||
        ex.class == Twitter::Error::Forbidden ||
        ex.message.include?('Connection reset by peer')
  end

  def pick_client(options)
    client = nil
    if options['user_id'] && options['user_id'] != -1
      user = User.find(options['user_id'])
      client = user.api_client if user.authorized?
    end

    client ? client : Bot.api_client
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
