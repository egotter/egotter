require 'active_support/concern'

module DeleteTweetsConcern
  extend ActiveSupport::Concern

  QUESTION_DELETE_TWEETS_REGEXP = /削除|全消し|ツイ消し|クリーナー/

  def delete_tweets_questioned?(text)
    text.length < 15 && text.match?(QUESTION_DELETE_TWEETS_REGEXP)
  end

  def answer_delete_tweets_question(uid)
    CreateDeleteTweetsQuestionedMessageWorker.perform_async(uid)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end
end
