require 'active_support/concern'

module Concerns::TwitterUser::Api
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
  end

  def one_sided_friends_rate
    (one_sided_friendships.size.to_f / friend_uids.size) rescue 0.0
  end

  def one_sided_followers_rate
    (one_sided_followerships.size.to_f / follower_uids.size) rescue 0.0
  end

  def follow_back_rate
    numerator = mutual_friendships.size
    denominator = follower_uids.size
    (numerator == 0 || denominator == 0) ? 0.0 : numerator.to_f / denominator
  rescue
    0.0
  end

  def mutual_friend_uids
    mutual_friendships.pluck(:friend_uid)
  end

  def conversations(other)
    statuses1 = status_tweets.select { |status| status.mention_to?(other.mention_name) }
    statuses2 = other.status_tweets.select { |status| status.mention_to?(mention_name) }
    (statuses1 + statuses2).sort_by { |status| -status.tweeted_at.to_i }
  end

  def replying_uids(uniq: true)
    return [] unless usage_stat
    uids = usage_stat.mentions.keys.map(&:to_s).map(&:to_i)
    uniq ? uids.uniq : uids
  end

  def replying(uniq: true)
    uids = replying_uids(uniq: uniq)
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def reply_tweets(login_user: nil)
    if login_user&.uid&.to_i == uid.to_i
      mention_tweets
    else
      mention_tweets.select { |status| !status.user&.protected }
    end
  end

  def replied_uids(uniq: true, login_user: nil)
    uids = reply_tweets(login_user: login_user).map { |tweet| tweet.user&.id }.compact
    uniq ? uids.uniq : uids
  end

  def replied(uniq: true, login_user: nil)
    users = reply_tweets(login_user: login_user).map(&:user).compact
    users.uniq!(&:id) if uniq
    users.each { |user| user.uid = user.id }
  end

  def replying_and_replied_uids(uniq: true, login_user: nil)
    replying_uids(uniq: uniq) & replied_uids(uniq: uniq, login_user: login_user)
  end

  def replying_and_replied(uniq: true, login_user: nil)
    uids = replying_and_replied_uids(uniq: uniq, login_user: login_user)
    users = (replying(uniq: uniq) + replied(uniq: uniq, login_user: login_user)).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end
end
