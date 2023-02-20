require 'digest/md5'

class CreateTwitterDBUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  prepend WorkUniqueness
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(data, options = {})
    Digest::MD5.hexdigest(data.to_s)
  end

  def unique_in
    10.seconds
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

    do_perform(uids, extract_user_id(options), options)
  rescue ApiClient::RetryExhausted => e
    CreateTwitterDBUserForRetryableErrorWorker.perform_in(rand(20) + 15, data, options.merge(debug_options(e)))
  rescue => e
    Airbag.exception e, uids: (decompress(data) rescue nil), options: options
    FailedCreateTwitterDBUserWorker.perform_async(data, options.merge(debug_options(e)))
  end

  private

  def do_perform(uids, user_id, options)
    uids -= TwitterDB::QueuedUser.where(uid: uids).pluck(:uid)
    return if uids.empty?

    TwitterDB::QueuedUser.mark_uids_as_processing(uids)
    users = client(user_id).safe_users(uids).map(&:to_h)

    if (suspended_uids = extract_suspended_uids(uids, users)).any?
      Airbag.info 'Import suspended uids', uids: uids, suspended_uids: suspended_uids
      ImportTwitterDBSuspendedUserWorker.perform_async(suspended_uids)
    end

    if users.any?
      ImportTwitterDBUserWorker.perform_in(rand(10) + 3, users, enqueued_by: options['enqueued_by'], _user_id: user_id, _size: users.size)
    end
  rescue ApiClient::StrangeHttpTimeout => e
    uids.each_slice(uids.size > 10 ? 10 : 1) do |group|
      self.class.perform_async(group, options)
    end
  end

  def extract_user_id(options)
    (options['user_id'] && options['user_id'].to_i != -1) ? options['user_id'] : nil
  end

  def client(user_id)
    if user_id && !RateLimitExceededFlag.on?(user_id)
      User.find(user_id).api_client.twitter
    else
      Bot.api_client.twitter
    end
  end

  def extract_suspended_uids(uids, users)
    uids.size == users.size ? [] : (uids - users.map { |u| u[:id] })
  end

  def debug_options(e = nil)
    {_time: Time.zone.now, _worker: self.class, error_class: e&.class, error_message: e&.message&.truncate(200)}.compact
  end

  class << self
    def perform_async(uids, options = {})
      uids.uniq.sort.each_slice(100).with_index do |group, i|
        unless TwitterDBUsersUpdatedFlag.on?(group)
          TwitterDBUsersUpdatedFlag.on(group)
          super(compress(group), options)
        end
      end
    end

    def push_bulk(uids, options = {})
      uids.uniq.sort.each_slice(100).with_index do |group, i|
        unless TwitterDBUsersUpdatedFlag.on?(group)
          TwitterDBUsersUpdatedFlag.on(group)
          perform_in((0.1 * i).floor, compress(group), options)
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
