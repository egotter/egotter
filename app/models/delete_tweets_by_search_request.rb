# == Schema Information
#
# Table name: delete_tweets_by_search_requests
#
#  id                 :bigint(8)        not null, primary key
#  user_id            :integer          not null
#  reservations_count :integer          default(0), not null
#  deletions_count    :integer          default(0), not null
#  send_dm            :boolean          default(FALSE), not null
#  post_tweet         :boolean          default(FALSE), not null
#  error_message      :text(65535)
#  filters            :json
#  tweet_ids          :json
#  finished_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_delete_tweets_by_search_requests_on_created_at  (created_at)
#  index_delete_tweets_by_search_requests_on_user_id     (user_id)
#
class DeleteTweetsBySearchRequest < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  def perform
    tweet_ids.each do |tweet_id|
      DeleteTweetBySearchWorker.perform_async(id, tweet_id)
    end
  end

  def last_tweet_id?(tweet_id)
    tweet_ids&.last&.to_i == tweet_id.to_i
  end

  def finished!
    if finished_at.nil?
      update!(finished_at: Time.zone.now)
      post_tweet!(true) if post_tweet
      send_dm!(true) if send_dm
    end
  end

  def post_tweet!(delay = false)
    if delay
      CreateTweetByDeleteTweetsBySearchRequestWorker.perform_in(1.minutes, id)
    else
      message = DeleteTweetsReport.finished_tweet(user, self).message
      user.api_client.twitter.update(message)
      SendMessageToSlackWorker.perform_async(:delete_tweets, "`Tweet` tweet=#{message} #{to_message}")
    end
  rescue => e
    raise FinishedTweetNotSent.new("exception=#{e.inspect} tweet=#{message} #{to_message}")
  end

  def send_dm!(delay = false)
    if delay
      CreateDirectMessageByDeleteTweetsBySearchRequestWorker.perform_in(1.minutes, id)
    else
      report = DeleteTweetsReport.finished_message_from_user(user)
      report.deliver!

      report = DeleteTweetsReport.finished_message(user, self)
      report.deliver!
    end
  rescue => e
    unless ignorable_direct_message_error?(e)
      raise FinishedDirectMessageNotSent.new("#{e.inspect} sender_uid=#{report.sender.uid}")
    end
  end

  def ignorable_direct_message_error?(e)
    DirectMessageStatus.not_following_you?(e) |
        DirectMessageStatus.cannot_send_messages?(e) ||
        DirectMessageStatus.you_have_blocked?(e)
  end

  def to_message
    {
        class: self.class,
        id: id,
        user_id: user_id,
        screen_name: user.screen_name,
        reservations_count: reservations_count,
        deletions_count: deletions_count,
    }.map { |k, v| "#{k}=#{v}" }.join(' ')
  end

  class FinishedTweetNotSent < StandardError; end

  class FinishedDirectMessageNotSent < StandardError; end
end
