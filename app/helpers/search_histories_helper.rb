module SearchHistoriesHelper
  include Concerns::SessionsConcern

  def current_search_histories
    return [] if from_crawler?
    condition = user_signed_in? ? {user_id: current_user_id} : {session_id: fingerprint}
    SearchHistory.includes(:twitter_db_user).where(condition).order(created_at: :desc).limit(10)
  end

  def search_histories_limit
    count = 0

    if user_signed_in?
      user = current_user

      count =
          if user.is_subscribing?
            user.orders.unexpired[-1].search_count
          else
            Rails.configuration.x.constants['free_plan_search_histories_limit']
          end

      if user.sharing_egotter?
        count += search_histories_sharing_bonus
      end
    else
      count = Rails.configuration.x.constants['anonymous_search_histories_limit']
    end

    count
  end

  def search_histories_sharing_bonus
    if user_signed_in?
      current_user.sharing_egotter_count * Rails.configuration.x.constants['search_histories_sharing_bonus']
    else
      0
    end
  end

  def search_histories_remaining
    [0, search_histories_limit - search_histories_size].max
  end

  private

  def search_histories_size
    condition = user_signed_in? ? {user_id: current_user_id} : {session_id: fingerprint}
    condition.merge!(created_at: 1.day.ago..Time.zone.now)
    SearchHistory.where(condition).size
  end
end
