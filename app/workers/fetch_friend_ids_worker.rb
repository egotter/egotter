class FetchFriendIdsWorker
  include Sidekiq::Worker
  include WorkerIdsFetcher
  include WorkerErrorHandler
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  # options:
  def perform(uid, cursor, options = {})
    res = fetch_friend_ids(uid, cursor)
    IdsFetcherCache.new(self.class).write(uid, cursor, res)
  rescue => e
    handle_worker_error(e, uid: uid, cursor: cursor, **options)
  end
end
