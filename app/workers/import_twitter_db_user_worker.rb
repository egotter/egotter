require 'digest/md5'

class ImportTwitterDBUserWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(uids, options = {})
    Digest::MD5.hexdigest(uids.to_s)
  end

  def unique_in
    10.seconds
  end

  def _timeout_in
    10.seconds
  end

  # options:
  def perform(compressed_users, options = {})
    users = compressed_users.is_a?(String) ? decompress(compressed_users) : compressed_users

    if users.empty?
      Airbag.warn "The users is empty options=#{options.inspect}"
      return
    end

    if users.size > 100
      Airbag.warn "More than 100 users are passed size=#{users.size} options=#{options.inspect}"
    end

    import_users(users)
  rescue Deadlocked => e
    Airbag.info "exception=#{e.inspect} cause=#{e.cause&.inspect&.truncate(200)}"
    FailedImportTwitterDBUserWorker.perform_async(users, options.merge(error_class: e.class))
  rescue => e
    handle_worker_error(e, users: users.size, options: options)
    FailedImportTwitterDBUserWorker.perform_async(users, options.merge(error_class: e.class))
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
    e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
  end

  class << self
    def perform_async_wrapper(users, options = {})
      if users.size > 100
        users.each_slice(100) do |users_array|
          perform_async_wrapper(users_array, options)
        end
      else
        perform_async(compress(users), options)
      end
    end

    def compress(users)
      Base64.encode64(Zlib::Deflate.deflate(users.to_json))
    end
  end

  def decompress(data)
    JSON.parse(Zlib::Inflate.inflate(Base64.decode64(data)))
  end
end
