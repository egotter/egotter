module SearchHistoriesHelper
  def current_search_histories
    return [] if from_crawler?
    condition = user_signed_in? ? {user_id: current_user_id} : {session_id: fingerprint}
    SearchHistory.includes(:twitter_db_user).where(condition).order(created_at: :desc).limit(10).select(&:twitter_db_user)
  end

  def search_histories_size
    condition = user_signed_in? ? {user_id: current_user_id} : {session_id: fingerprint}
    condition.merge!(created_at: 1.day.ago..Time.zone.now)
    SearchHistory.where(condition).count('distinct uid')
  end

  def search_histories_remaining
    [0, search_histories_limit - search_histories_size].max
  end

  def search_histories_limit
    if user_signed_in?
      if current_user.is_subscribing?
        current_user.orders.unexpired[-1].search_count
      else
        Rails.configuration.x.constants['free_plan_search_histories_limit']
      end
    else
      Rails.configuration.x.constants['anonymous_search_histories_limit']
    end
  end

  def remaining_count_text
    "#{t('searches.common.search_remaining')} #{t('search_histories.remaining', count: search_histories_remaining)}"
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
