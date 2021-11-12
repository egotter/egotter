module DeleteTweetsHelper
  def delete_tweets_search_tab?
    delete_tweets_mypage_search_path.remove(/\?.+/) == request.path
  end

  def delete_tweets_free_tab?
    delete_tweets_mypage_path.remove(/\?.+/) == request.path
  end

  def delete_tweets_premium_tab?
    delete_tweets_mypage_premium_path.remove(/\?.+/) == request.path
  end
end
