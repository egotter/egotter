module SearchHistoriesHelper
  include Concerns::SessionsConcern

  def current_search_histories
    return [] if from_crawler?
    condition = user_signed_in? ? {user_id: current_user.id} : {session_id: egotter_visit_id}
    SearchHistory.includes(:twitter_db_user).where(condition).order(created_at: :desc).limit(10)
  end
end
