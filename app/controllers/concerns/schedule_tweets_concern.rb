require 'active_support/concern'

module ScheduleTweetsConcern
  extend ActiveSupport::Concern

  QUESTION_SCHEDULE_TWEETS_REGEXP = /(ツイート(\s|　)*予約)|予約投稿/

  def schedule_tweets_questioned?(dm)
    dm.text.length < 15 && dm.text.match?(QUESTION_SCHEDULE_TWEETS_REGEXP)
  end

  def answer_schedule_tweets_question(dm)
    CreateScheduleTweetsQuestionedMessageWorker.perform_async(dm.sender_id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
