# == Schema Information
#
# Table name: deletable_tweets
#
#  id             :bigint(8)        not null, primary key
#  uid            :bigint(8)        not null
#  tweet_id       :bigint(8)        not null
#  retweet_count  :integer
#  favorite_count :integer
#  tweeted_at     :datetime         not null
#  hashtags       :json
#  user_mentions  :json
#  urls           :json
#  media          :json
#  properties     :json
#  deleted_at     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_deletable_tweets_on_created_at        (created_at)
#  index_deletable_tweets_on_tweet_id          (tweet_id)
#  index_deletable_tweets_on_uid_and_tweet_id  (uid,tweet_id) UNIQUE
#
class DeletableTweet < ApplicationRecord

  validates :uid, presence: true
  validates :tweet_id, presence: true
  validates :tweeted_at, presence: true
  validates :uid, uniqueness: {scope: :tweet_id}

  class << self
    def from_array(array)
      array.map { |hash| from_hash(hash) }
    end

    # user_timeline(tweet_mode: 'extended')
    def from_hash(hash)
      if hash[:full_text]
        hash[:text] = hash.delete(:full_text)
        hash.dig(:entities, :urls)&.each do |entity|
          hash[:text].gsub!(entity[:url], entity[:expanded_url])
        end
      end

      new(
          uid: hash.dig(:user, :id),
          tweet_id: hash[:id],
          retweet_count: hash[:retweet_count],
          favorite_count: hash[:favorite_count],
          tweeted_at: Time.zone.parse(hash[:created_at]),
          hashtags: hash.dig(:entities, :hashtags),
          user_mentions: hash.dig(:entities, :user_mentions),
          urls: hash.dig(:entities, :urls),
          media: hash.dig(:extended_entities, :media),
          properties: hash,
      )
    end
  end
end
