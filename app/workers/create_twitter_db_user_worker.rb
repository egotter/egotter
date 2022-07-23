require 'digest/md5'

class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(data, options = {})
    Digest::MD5.hexdigest(data.to_s)
  end

  def unique_in
    10.seconds
  end

  def after_skip(data, options = {})
    SkippedCreateTwitterDBUserWorker.perform_async(data, options.merge(_size: (decompress(data).size rescue -1)).merge(debug_options))
  end

  def timeout_in
    10.seconds
  end

  # options:
  #   force_update
  #   user_id
  #   enqueued_by
  def perform(data, options = {})
    uids = decompress(data)

    if uids.empty?
      Airbag.warn "the size of uids is 0 options=#{options.inspect}"
      return
    end

    if uids.size > 100
      Airbag.warn "the size of uids is greater than 100 options=#{options.inspect}"
    end

    user_id = (options['user_id'] && options['user_id'].to_i != -1) ? options['user_id'] : nil

    task = CreateTwitterDBUsersTask.new(uids, user_id: user_id, force: options['force_update'], enqueued_by: options['enqueued_by'])
    task.start
  rescue ApiClient::RetryExhausted => e
    Airbag.info "Retry retryable error: #{e.inspect.truncate(200)}"
    delay = rand(20) + 15
    CreateTwitterDBUserForRetryableErrorWorker.perform_in(delay, data, options.merge(debug_options(e)))
  rescue ApiClient::ContainStrangeUid => e
    if uids && uids.size > 1
      slice_and_retry(uids, options)
    else
      Airbag.info "#{e.message} uids=#{uids.inspect} options=#{options.inspect}"
    end
  rescue => e
    handle_worker_error(e, uids_size: uids.size, options: options)
    FailedCreateTwitterDBUserWorker.perform_async(uids, options.merge(debug_options(e)))
  end

  private

  def slice_and_retry(uids, options)
    slice_size = (uids.size > 10) ? 10 : 1
    uids.each_slice(slice_size) do |partial_uids|
      self.class.perform_async(partial_uids, options)
    end
  end

  def debug_options(e = nil)
    {_time: Time.zone.now, _worker: self.class, error_class: e&.class, error_message: e&.message&.truncate(200)}.compact
  end

  class << self
    def perform_async(total_uids, options = {})
      total_uids.uniq.each_slice(100) do |uids|
        unless TwitterDBUsersUpdatedFlag.on?(uids)
          TwitterDBUsersUpdatedFlag.on(uids)
          super(compress(uids), options)
        end
      end
    end

    def compress(uids)
      uids.size > 10 ? Base64.encode64(Zlib::Deflate.deflate(uids.join(','))) : uids
    end
  end

  def decompress(data)
    data.is_a?(String) ? Zlib::Inflate.inflate(Base64.decode64(data)).split(',').map(&:to_i) : data
  end
end
