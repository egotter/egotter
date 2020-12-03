module CloseFriendsConcern
  def process_close_friends(dm)
    if close_friends_questioned?(dm.text)
      answer_close_friends_question(dm.sender_id)
      return true
    end

    false
  end

  QUESTION_CLOSE_FRIENDS_REGEXP = /仲良しランキング|(^(仲良し|ランキング)$)/

  def close_friends_questioned?(text)
    text.length < 15 && text.match?(QUESTION_CLOSE_FRIENDS_REGEXP)
  end

  def answer_close_friends_question(uid)
    CreateCloseFriendsQuestionedMessageWorker.perform_async(uid)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end
end
