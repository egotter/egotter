require 'digest/md5'

class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
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
    target_uids = uids.is_a?(String) ? decompress(uids) : uids

    if target_uids.empty?
      logger.warn "the size of uids is 0 options=#{options.inspect}"
      return
    end

    if target_uids.size > 100
      logger.warn "the size of uids is greater than 100 options=#{options.inspect}"
    end

    user_id = (options['user_id'] && options['user_id'].to_i != -1) ? options['user_id'] : nil

    task = CreateTwitterDBUsersTask.new(target_uids, user_id: user_id, force: options['force_update'])
    task.start
    Rails.logger.info "CreateTwitterDBUsersTask: DEBUG enqueued_by=#{options['enqueued_by']} user_id=#{user_id} #{task.debug_message}"
  rescue CreateTwitterDBUsersTask::RetryDeadlockExhausted => e
    logger.info "Retry deadlock error: #{e.inspect.truncate(200)}"
    delay = rand(3) + 1
    CreateTwitterDBUserForRetryingDeadlockWorker.perform_in(delay, uids, options.merge(klass: self.class, error_class: e.class))
  rescue => e
    if e.class == ApiClient::ContainStrangeUid
      if target_uids && target_uids.size > 1
        slice_and_retry(target_uids, options)
      else
        logger.info "#{e.message} uids=#{target_uids.inspect} options=#{options.inspect}"
      end
    else
      handle_worker_error(e, uids_size: target_uids.size, uids: target_uids, options: options)
      FailedCreateTwitterDBUserWorker.perform_async(target_uids, options.merge(klass: self.class, error_class: e.class))
    end
  end

  private

  def slice_and_retry(uids, options)
    slice_size = (uids.size > 10) ? 10 : 1
    uids.each_slice(slice_size) do |partial_uids|
      self.class.perform_async(partial_uids, options)
    end
  end

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
