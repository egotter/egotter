require 'digest/md5'

class ImportTwitterDBUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(users, options = {})
    Digest::MD5.hexdigest(users.to_json)
  end

  def unique_in
    10.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(users, options = {})
    users = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(users))) if users.is_a?(String)
    import_users(users)
  rescue Deadlocked => e
    delay = rand(20) + 15
    ImportTwitterDBUserForRetryingDeadlockWorker.perform_in(delay, users, options.merge(klass: self.class, error_class: e.class))
  rescue => e
    handle_worker_error(e, users: users.size, options: options)
    FailedImportTwitterDBUserWorker.perform_async(users, options.merge(klass: self.class, error_class: e.class))
  end

  private

  def import_users(users)
    users.each(&:deep_symbolize_keys!)
    TwitterDB::User.import_by!(users: users)
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

  class << self
    def perform_async(users, options = {})
      if users.size > 1
        users = Base64.encode64(Zlib::Deflate.deflate(users.to_json))
      end
      super(users, options)
    end
  end
end
