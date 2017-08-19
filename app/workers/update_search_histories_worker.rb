class UpdateSearchHistoriesWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(session_id, user_id, uid)
    condition = (user_id.to_s == '-1') ? {session_id: session_id} : {user_id: user_id}
    latest = SearchHistory.order(created_at: :desc).find_by(condition)

    if !latest || latest.uid.to_i != uid.to_i
      SearchHistory.create!(session_id: session_id, user_id: user_id, uid: uid)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id} #{uid}"
  end
end
