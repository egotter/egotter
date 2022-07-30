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
    Airbag.info "#{e.class} found", options: options
    delay = rand(20) + 15
    ImportTwitterDBUserForRetryingDeadlockWorker.perform_in(delay, data, options.merge(debug_options(e)))
  rescue => e
    Airbag.exception e, options: options
    FailedImportTwitterDBUserWorker.perform_async(data, options.merge(debug_options(e)))
  end

  private

  def import_users(users)
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

  class JobConsumer
    def initialize(loop: 300, limit: 100, timeout: 100)
      @loop = loop
      @limit = limit
      @timeout = timeout
      @worker = ImportTwitterDBUserWorker
    end

    def start
      start_time = Time.zone.now
      @processed_count = 0
      @errors_count = 0

      @loop.times do
        jobs = collect_jobs(@limit)
        jobs.each(&:delete)

        jobs.each do |job|
          @worker.new.perform(*job.args)
          @processed_count += 1
        rescue => e
          logger.warn "#{self.class}: #{e.inspect}"
          @errors_count += 1
        end

        if Time.zone.now - start_time > @timeout
          logger.info "#{self.class}: Timeout"
          break
        end

        sleep 0.5
      end
    end

    def format_progress
      "processed=#{@processed_count}#{" errors=#{@errors_count}" if @errors_count > 0}"
    end

    private

    def collect_jobs(limit)
      jobs = []

      Sidekiq::ScheduledSet.new.scan(@worker.name).each do |job|
        if job.klass == @worker.name
          jobs << job
        end

        if jobs.size >= limit
          break
        end
      end

      jobs
    end

    def logger
      ::Logger.new(STDOUT)
    end
  end
end
