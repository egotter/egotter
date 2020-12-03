module DeleteTweetsConcern
  def process_delete_tweets(dm)
    if delete_tweets_questioned?(dm.text)
      answer_delete_tweets_question(dm.sender_id)
      return true
    end

    false
  end

  QUESTION_DELETE_TWEETS_REGEXP = /削除|消去|全消し|ツイ消し|クリーナー/

  def delete_tweets_questioned?(text)
    text.length < 15 && text.match?(QUESTION_DELETE_TWEETS_REGEXP)
  end

  def answer_delete_tweets_question(uid)
    CreateDeleteTweetsQuestionedMessageWorker.perform_async(uid)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end
end
