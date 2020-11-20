require 'digest/md5'

class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  include AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(uids, options = {})
    Digest::MD5.hexdigest(uids.to_s)
  end

  def unique_in
    10.minutes
  end

  def _timeout_in
    10.seconds
  end

  # options:
  #   compressed
  #   force_update
  #   user_id
  #   enqueued_by
  def perform(uids, options = {})
    if options['compressed'] && uids.is_a?(String)
      uids = decompress(uids)
    end

    if uids.size > 100
      logger.warn "the size of uids is greater than 100 options=#{options.inspect}"
    end

    user = User.find_by(id: options['user_id']) if options['user_id'] && options['user_id'] != -1
    user = Bot unless user
    do_perform(user.api_client, uids, options)

  rescue => e
    # Errno::EEXIST File exists @ dir_s_mkdir
    # Errno::ENOENT No such file or directory @ rb_sysopen
    logger.warn "#{e.inspect.truncate(150)} options=#{options.inspect.truncate(150)}"
    logger.info e.backtrace.join("\n")
    FailedCreateTwitterDBUserWorker.perform_async(uids, options.merge(klass: self.class))
  end

  private

  def do_perform(client, uids, options)
    TwitterDBUserBatch.new(client).import!(uids, force_update: options['force_update'])
  rescue => e
    exception_handler(e)
    client = Bot.api_client
    retry
  end

  def exception_handler(e)
    @retries ||= 3

    unless meet_requirements_for_retrying?(e) && (@retries -= 1) >= 0
      raise RetryExhausted.new(e.inspect.truncate(100))
    end
  end

  def meet_requirements_for_retrying?(e)
    TwitterApiStatus.unauthorized?(e) ||
        TwitterApiStatus.temporarily_locked?(e) ||
        TwitterApiStatus.forbidden?(e) ||
        TwitterApiStatus.too_many_requests?(e) ||
        ServiceStatus.retryable_error?(e)
  end

  class RetryExhausted < StandardError; end

  class << self
    def compress_and_perform_async(uids, options = {})
      if uids.size > 100
        uids.each_slice(100) do |uids_array|
          compress_and_perform_async(uids_array, options)
        end
      else
        uids = compress(uids)
        options[:compressed] = true
        perform_async(uids, options)
      end
    end

    def compress(uids)
      Base64.encode64(Zlib::Deflate.deflate(uids.join(',')))
    end
  end

  def decompress(data)
    Zlib::Inflate.inflate(Base64.decode64(data)).split(',').map(&:to_i)
  end
end
