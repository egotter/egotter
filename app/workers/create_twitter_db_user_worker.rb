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
  #   user_id
  #   enqueued_by
  def perform(data, options = {})
    uids = decompress(data)

    if uids.empty?
      Airbag.warn 'the size of uids is 0', options: options
      return
    end

    if uids.size > 100
      Airbag.warn 'the size of uids is greater than 100', options: options
    end

    do_perform(uids, options)
  rescue ApiClient::RetryExhausted => e
    CreateTwitterDBUserForRetryableErrorWorker.perform_in(rand(20) + 15, data, options.merge(debug_options(e)))
  rescue => e
    Airbag.exception e, uids: (decompress(data) rescue nil), options: options
    FailedCreateTwitterDBUserWorker.perform_async(data, options.merge(debug_options(e)))
  end

  private

  def do_perform(uids, options)
    user_id = extract_user_id(options)
    CreateTwitterDBUsersTask.new(uids, user_id: user_id, enqueued_by: options['enqueued_by']).start
  rescue ApiClient::StrangeHttpTimeout => e
    uids.each_slice(uids.size > 10 ? 10 : 1) do |group|
      self.class.perform_async(group, options)
    end
  end

  def extract_user_id(options)
    (options['user_id'] && options['user_id'].to_i != -1) ? options['user_id'] : nil
  end

  def debug_options(e = nil)
    {_time: Time.zone.now, _worker: self.class, error_class: e&.class, error_message: e&.message&.truncate(200)}.compact
  end

  class << self
    def push_bulk(uids, options = {})
      uids.uniq.sort.each_slice(100) do |group|
        unless TwitterDBUsersUpdatedFlag.on?(group)
          TwitterDBUsersUpdatedFlag.on(group)
          perform_async(compress(group), options)
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
