module SearchHistoriesHelper

  def search_histories_list
    user_id = current_user_id
    histories = Util::SearchHistories.new(redis)
    if histories.exists?(user_id)
      JSON.parse(histories.get(user_id)).map { |user| Hashie::Mash.new(user) }
    else
      CreateSearchHistoriesWorker.perform_async(user_id)
      []
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message}"
    []
  end
end
