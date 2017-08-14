class UpdateSearchHistoriesWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(user_id, uid)
    latest = SearchHistory.order(created_at: :desc).find_by(user_id: user_id)
    if !latest || latest.uid.to_i != uid.to_i
      SearchHistory.create!(user_id: user_id, uid: uid)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id} #{uid}"
  end
end
