# == Schema Information
#
# Table name: deletable_tweets
#
#  id                   :bigint(8)        not null, primary key
#  uid                  :bigint(8)        not null
#  tweet_id             :bigint(8)        not null
#  retweet_count        :integer
#  favorite_count       :integer
#  tweeted_at           :datetime         not null
#  hashtags             :json
#  user_mentions        :json
#  urls                 :json
#  media                :json
#  properties           :json
#  deletion_reserved_at :datetime
#  deleted_at           :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
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

  scope :deletion_reserved, -> { where.not(deletion_reserved_at: nil) }
  scope :not_deletion_reserved, -> { where(deletion_reserved_at: nil) }

  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :not_deleted, -> { where(deleted_at: nil) }

  def user
    User.find_by(uid: uid)
  end

  def delete_tweet!
    destroy_status!
  rescue => e
    update(deletion_reserved_at: nil)
    # TODO update(deletion_failed_at: Time.zone.now)
    raise
  end

  private

  def destroy_status!
    user.api_client.twitter.destroy_status(tweet_id)
    update(deleted_at: Time.zone.now)
  rescue => e
    if TwitterApiStatus.invalid_or_expired_token?(e) ||
        TwitterApiStatus.suspended?(e) ||
        TweetStatus.no_status_found?(e) ||
        TweetStatus.not_authorized?(e) ||
        TweetStatus.temporarily_locked?(e) ||
        TweetStatus.that_page_does_not_exist?(e) ||
        TweetStatus.forbidden?(e)
      nil
    else
      raise
    end
  end

  class << self
    def reserve_deletion(user, tweet_ids)
      not_deleted.not_deletion_reserved.where(uid: user.uid, tweet_id: tweet_ids).update_all(deletion_reserved_at: Time.zone.now)
    end

    def from_response(response)
      from_array(response.map(&:attrs))
    end

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
          media: hash.dig(:extended_entities, :media) || [],
          properties: hash,
      )
    end
  end
end
