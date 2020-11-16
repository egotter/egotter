module ScheduleTweetsConcern
  def process_schedule_tweets(dm)
    if schedule_tweets_questioned?(dm.text)
      answer_schedule_tweets_question(dm.sender_id)
      return true
    end

    false
  end

  QUESTION_SCHEDULE_TWEETS_REGEXP = /予約/

  def schedule_tweets_questioned?(text)
    text.length < 15 && text.match?(QUESTION_SCHEDULE_TWEETS_REGEXP)
  end

  def answer_schedule_tweets_question(uid)
    CreateScheduleTweetsQuestionedMessageWorker.perform_async(uid)
  end
end
