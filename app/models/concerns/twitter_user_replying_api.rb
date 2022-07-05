require 'active_support/concern'

module TwitterUserReplyingApi
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
  end

  # TODO Remove later
  def conversations(other)
    statuses1 = status_tweets.select { |status| status.mention_to?(other.mention_name) }
    statuses2 = other.status_tweets.select { |status| status.mention_to?(mention_name) }
    (statuses1 + statuses2).sort_by { |status| -status.tweeted_at.to_i }
  end

  def replying_uids(uniq: true)
    if usage_stat
      uids = usage_stat.mention_uids
    else
      uids = UsageStat::Builder.new(uid).send(:extract_mentions, status_tweets).keys.map(&:to_s).map(&:to_i)
    end
    uniq ? uids.uniq : uids
  end

  def replying(uniq: true)
    uids = replying_uids(uniq: uniq)
    TwitterDB::User.order_by_field(uids).where(uid: uids)
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
