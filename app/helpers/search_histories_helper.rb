module SearchHistoriesHelper

  TTL = Rails.env.development? ? 1.minute : 5.minutes

  def search_histories_list
    user_id = current_user_id
    key = "search_histories:#{user_id}"
    if redis.exists(key)
      JSON.parse(redis.get(key)).map { |user| Hashie::Mash.new(user) }
    else
      CreateSearchHistoriesWorker.perform_async(user_id, TTL)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message}"
    []
  end
end
