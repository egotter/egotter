require 'active_support/concern'

module Concerns::TwitterUser::AssociationBuilder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::Validation

  class_methods do
  end

  included do
  end

  def attach_friend_uids(uids)
    if uids&.any?
      @reserved_friend_uids = uids
      self.friends_size = uids.size
    else
      @reserved_friend_uids = []
      self.friends_size = 0
    end
  end

  def attach_follower_uids(uids)
    if uids&.any?
      @reserved_follower_uids = uids
      self.followers_size = uids.size
    else
      @reserved_follower_uids = []
      self.followers_size = 0
    end
  end

  def attach_user_timeline(tweets)
    if tweets&.any?
      @reserved_statuses = tweets.map { |status| TwitterDB::Status.build_by(twitter_user: self, status: status) }
    else
      @reserved_statuses = []
    end
  end

  def attach_mentions_timeline(tweets, search_result)
    if (tweets.nil? || tweets.empty?) && search_result&.any?
      tweets = reject_self_tweet_and_retweet(search_result)
    end

    if tweets&.any?
      @reserved_mentions = tweets.map { |status| TwitterDB::Mention.build_by(twitter_user: self, status: status) }
    else
      @reserved_mentions = []
    end
  end

  def reject_self_tweet_and_retweet(tweets)
    tweets.reject { |status| uid == status[:user][:id] || status[:text].start_with?("RT @#{screen_name}") }
  end

  def attach_favorite_tweets(tweets)
    if tweets&.any?
      @reserved_favorites = tweets.map { |status| TwitterDB::Favorite.build_by(twitter_user: self, status: status) }
    else
      @reserved_favorites = []
    end
  end
end
