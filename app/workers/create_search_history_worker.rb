class CreateSearchHistoryWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_high', retry: 0, backtrace: false

  def perform(uid, session_id:, user_id:, ahoy_visit_id:, via:)
    condition = (user_id == -1) ? {session_id: session_id} : {user_id: user_id}
    latest = SearchHistory.order(created_at: :desc).find_by(condition)

    if !latest || latest.uid != uid
      SearchHistory.create!(session_id: session_id, user_id: user_id, uid: uid, ahoy_visit_id: ahoy_visit_id, via: via)
    end
  rescue => e
    Airbag.exception e, uid: uid, session_id: session_id, user_id: user_id, ahoy_visit_id: ahoy_visit_id, via: via
  end
end
