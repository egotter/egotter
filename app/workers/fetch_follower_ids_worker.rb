class FetchFollowerIdsWorker
  include Sidekiq::Worker
  include WorkerIdsFetcher
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    10.minutes
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(uid, loop_limit, options = {})
    ids = fetch_ids(:follower_ids, uid, loop_limit)
    IdsFetcherCache.new(self.class).write(uid, ids)
  rescue => e
    handle_worker_error(e, uid: uid, **options)
  end
end
