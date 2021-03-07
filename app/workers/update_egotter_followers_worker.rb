class UpdateEgotterFollowersWorker
  include Sidekiq::Worker
  include WorkerErrorHandler
  prepend TimeoutableWorker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    30.minutes
  end

  def _timeout_in
    3.minute
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(options = {})
    uids = benchmark('collect_uids') { EgotterFollower.collect_uids }
    benchmark('import_uids') { EgotterFollower.import_uids(uids) }
    uids = benchmark('filter_unnecessary_uids') { EgotterFollower.filter_unnecessary_uids(uids) }
    benchmark('delete_uids') { EgotterFollower.delete_uids(uids) }
  rescue => e
    handle_worker_error(e, **options)
  end

  private

  def benchmark(message, &block)
    ApplicationRecord.benchmark("Benchmark UpdateEgotterFollowersWorker #{message}", level: :info) do
      yield
    end
  end
end
