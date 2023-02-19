require 'digest/md5'

class ImportTwitterDBUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(data, options = {})
    Digest::MD5.hexdigest(data.to_json)
  end

  def unique_in
    10.seconds
  end

  def after_skip(data, options = {})
    SkippedImportTwitterDBUserWorker.perform_async(data, options.merge(_size: (decompress(data).size rescue -1)).merge(debug_options))
  end

  def timeout_in
    10.seconds
  end

  # options:
  def perform(data, options = {})
    users = decompress(data)
    users.each(&:deep_symbolize_keys!)
    import_users(users)
    TwitterDB::QueuedUser.mark_uids_as_processed(users.map { |u| u[:id] })
  rescue Deadlocked => e
    opt = options.merge(debug_options(e))
    ImportTwitterDBUserForRetryingDeadlockWorker.perform_in(rand(20) + 15, data, opt)
    Airbag.info "#{e.class} found", options: opt
    SendMessageToSlackWorker.perform_async(:job_deadlock, "#{self.class}##{__method__}: #{opt}")
  rescue => e
    Airbag.exception e, options: options
    FailedImportTwitterDBUserWorker.perform_async(data, options.merge(debug_options(e)))
  end

  private

  def import_users(users)
    TwitterDB::User.import_by!(users: users)
    ImportTwitterDBUserIdWorker.perform_in(rand(10) + 3, users.map { |u| u[:id] })
  rescue => e
    if deadlock_error?(e)
      raise Deadlocked
    else
      raise
    end
  end

  class Deadlocked < StandardError; end

  # ActiveRecord::StatementInvalid
  # ActiveRecord::Deadlocked
  def deadlock_error?(e)
    e.message.include?('try restarting transaction')
  end

  def decompress(data)
    data.is_a?(String) ? JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data))) : data
  end

  def debug_options(e = nil)
    {_time: Time.zone.now, _worker: self.class, error_class: e&.class, error_message: e&.message&.truncate(200)}.compact
  end

  class << self
    def perform_async(users, options = {})
      super(compress(users), options)
    end

    def compress(users)
      users.size > 3 ? Base64.encode64(Zlib::Deflate.deflate(users.to_json)) : users
    end
  end
end
