# == Schema Information
#
# Table name: create_deletable_tweets_requests
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_create_deletable_tweets_requests_on_created_at  (created_at)
#  index_create_deletable_tweets_requests_on_user_id     (user_id)
#
class CreateDeletableTweetsRequest < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  def perform
    collect_tweets_with_max_id do |response|
      tweets = DeletableTweet.from_response(response)
      save_tweets(tweets)
    end
  end

  private

  def save_tweets(tweets)
    DeletableTweet.import tweets, validate: false
  rescue => e
    Airbag.warn "Stop bulk importing and save each tweet exception=#{e.inspect}"
    tweets.each do |tweet|
      tweet.save if tweet.valid?
    end
  end

  def collect_tweets_with_max_id(&block)
    collection = []
    max_id = nil
    options = {count: 200, tweet_mode: 'extended'}
    client = user.api_client.twitter

    30.times do
      options[:max_id] = max_id unless max_id.nil?
      response = client.user_timeline(options)
      break if response.nil? || response.empty?

      collection.concat(response)
      break unless yield(response)
      max_id = response.last.id - 1
    end

    collection
  rescue => e
    raise e unless TwitterApiStatus.invalid_or_expired_token?(e)
  end
end
