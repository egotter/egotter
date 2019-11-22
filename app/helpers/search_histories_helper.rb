module SearchHistoriesHelper
  include Concerns::SessionsConcern

  def current_search_histories
    return [] if from_crawler?
    condition = user_signed_in? ? {user_id: current_user.id} : {session_id: fingerprint}
    SearchHistory.includes(:twitter_db_user).where(condition).order(created_at: :desc).limit(10)
  end

  def search_histories_limit
    count = Rails.configuration.x.constants['anonymous_search_histories_limit']

    if user_signed_in?
      count += search_histories_sign_in_bonus
    end

    if user_signed_in? && current_user.is_subscribing?
      count = user.orders.unexpired[-1].search_count
    end

    if user_signed_in? && current_user.sharing_egotter_count > 0
      count += current_user.sharing_egotter_count * search_histories_sharing_bonus
    end

    count
  end

  def search_histories_sign_in_bonus
    Rails.configuration.x.constants['search_histories_sign_in_bonus']
  end

  def search_histories_sharing_bonus
    Rails.configuration.x.constants['search_histories_sharing_bonus']
  end

  def search_histories_remaining
    [0, search_histories_limit - search_histories_size].max
  end

  def search_histories_duration
    1
  end

  def search_histories_size
    condition = user_signed_in? ? {user_id: current_user.id} : {session_id: fingerprint}
    condition.merge!(created_at: search_histories_duration.day.ago..Time.zone.now)
    SearchHistory.where(condition).size
  end
end
