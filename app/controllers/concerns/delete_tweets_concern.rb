require 'active_support/concern'

module DeleteTweetsConcern
  extend ActiveSupport::Concern

  QUESTION_DELETE_TWEETS_REGEXP = /ツイート(\s|　)*(削除|全消し|クリーナー)/

  def delete_tweets_questioned?(dm)
    dm.text.length < 15 && dm.text.match?(QUESTION_DELETE_TWEETS_REGEXP)
  end

  def answer_delete_tweets_question(dm)
    CreateDeleteTweetsQuestionedMessageWorker.perform_async(dm.sender_id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
