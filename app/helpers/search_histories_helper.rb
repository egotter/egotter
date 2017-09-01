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
end
