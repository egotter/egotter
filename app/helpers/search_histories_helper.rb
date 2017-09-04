module SearchHistoriesHelper
  def latest_search_histories
    if from_crawler?
      []
    else
      condition = user_signed_in? ? {user_id: current_user_id} : {session_id: fingerprint}
      SearchHistory.latest(condition)
    end
  end

  def today_search_histories_size
    start = 1.day.ago
    SearchHistory.where(created_at: start..Time.zone.now, session_id: fingerprint).size
  end

  def update_search_histories_when_signing_in(user)
    SearchHistory.where(session_id: fingerprint).update_all(user_id: user.id)
    SearchHistory.where(user_id: user.id).update_all(session_id: fingerprint)
  end

  def update_search_histories_when_signing_out(&block)
    old_session_id = fingerprint
    yield
    new_session_id = fingerprint
    SearchHistory.where(session_id: old_session_id).update_all(session_id: new_session_id)
    logger.info "#{old_session_id} turned into #{new_session_id}."
  end
end
