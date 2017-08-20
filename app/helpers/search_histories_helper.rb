module SearchHistoriesHelper
  def latest_search_histories
    user_signed_in? ? SearchHistory.latest(user_id: current_user_id) : SearchHistory.latest(session_id: session[:fingerprint])
  end

  def today_search_histories_size
    start = 1.day.ago
    SearchHistory.where(created_at: start..Time.zone.now).size
  end
end
