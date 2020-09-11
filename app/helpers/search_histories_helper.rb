module SearchHistoriesHelper
  include SessionsConcern

  def current_search_histories(limit: 10)
    return [] if from_crawler?
    condition = user_signed_in? ? {user_id: current_user.id} : {session_id: egotter_visit_id}
    SearchHistory.includes(:twitter_db_user).where(condition).order(created_at: :desc).limit(limit)
  end
end
