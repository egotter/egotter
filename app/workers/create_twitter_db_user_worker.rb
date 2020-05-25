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
    do_perform(client, uids, options)

  rescue => e
    # Errno::EEXIST File exists @ dir_s_mkdir
    # Errno::ENOENT No such file or directory @ rb_sysopen
    logger.warn DebugMessage.new(e, uids, options)
    notify_airbrake(e)
  end

  private

  def do_perform(client, uids, options)
    TwitterDB::User::Batch.fetch_and_import!(uids, client: client, force_update: options['force_update'])
  rescue => e
    exception_handler(e, options)
    client = Bot.api_client
    retry
  end

  def exception_handler(e, options)
    if log_error?(e)
      logger.warn "Retry with a bot client #{DebugMessage.new(e, nil, options)}"
    end

    @retries ||= 2

    if meet_requirements_for_retrying?(e) && @retries > 0
      @retries -= 1
    else
      raise RetryExhausted.new(DebugMessage.new(e, nil, options))
    end
  end

  def log_error?(e)
    !AccountStatus.unauthorized?(e) &&
        !AccountStatus.temporarily_locked?(e) &&
        !AccountStatus.too_many_requests?(e)
  end

  def meet_requirements_for_retrying?(e)
    AccountStatus.unauthorized?(e) ||
        AccountStatus.forbidden?(e) ||
        AccountStatus.too_many_requests?(e) ||
        ServiceStatus.retryable_error?(e)
  end

  def pick_client(options)
    if options['user_id'] && options['user_id'] != -1 && (user = User.find_by(id: options['user_id'])) && user.authorized?
      user.api_client
    else
      Bot.api_client
    end
  end

  class DebugMessage < String
    def initialize(e, uids, options)
      e = e.inspect.truncate(150)
      uids = uids.inspect.truncate(150)
      options = options.inspect
      super("#{e} uids=#{uids} options=#{options}")
    end
  end

  class RetryExhausted < StandardError
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
