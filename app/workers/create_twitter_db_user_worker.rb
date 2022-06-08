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
    SkippedCreateTwitterDBUserWorker.perform_async(data, options.merge(_size: (decompress(data).size rescue -1), _time: Time.zone.now))
  end

  def _timeout_in
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

    task = CreateTwitterDBUsersTask.new(uids, user_id: user_id, force: options['force_update'])
    task.start
    Airbag.info "CreateTwitterDBUsersTask: DEBUG enqueued_by=#{options['enqueued_by']} user_id=#{user_id} #{task.debug_message}"
  rescue CreateTwitterDBUsersTask::RetryDeadlockExhausted => e
    Airbag.info "Retry deadlock error: #{e.inspect.truncate(200)}"
    delay = rand(20) + 15
    CreateTwitterDBUserForRetryingDeadlockWorker.perform_in(delay, data, options.merge(klass: self.class, error_class: e.class))
  rescue ApiClient::RetryExhausted => e
    Airbag.info "Retry retryable error: #{e.inspect.truncate(200)}"
    delay = rand(20) + 15
    CreateTwitterDBUserForRetryableErrorWorker.perform_in(delay, data, options.merge(klass: self.class, error_class: e.class))
  rescue ApiClient::ContainStrangeUid => e
    if uids && uids.size > 1
      slice_and_retry(uids, options)
    else
      Airbag.info "#{e.message} uids=#{uids.inspect} options=#{options.inspect}"
    end
  rescue => e
    handle_worker_error(e, uids_size: uids.size, options: options)
    FailedCreateTwitterDBUserWorker.perform_async(uids, options.merge(klass: self.class, error_class: e.class))
  end

  private

  def slice_and_retry(uids, options)
    slice_size = (uids.size > 10) ? 10 : 1
    uids.each_slice(slice_size) do |partial_uids|
      self.class.perform_async(partial_uids, options)
    end
  end

  class << self
    def perform_async(uids, options = {})
      uids = uids.uniq

      if uids.size > 100
        uids.each_slice(100) do |uids_array|
          perform_async(uids_array, options)
        end
      else
        if uids.size > 10
          uids = compress(uids)
        end
        super(uids, options)
      end
    end

    def compress(uids)
      Base64.encode64(Zlib::Deflate.deflate(uids.join(',')))
    end
  end

  def decompress(data)
    data.is_a?(String) ? Zlib::Inflate.inflate(Base64.decode64(data)).split(',').map(&:to_i) : data
  end
end
