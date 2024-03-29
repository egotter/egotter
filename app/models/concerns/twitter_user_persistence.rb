require 'active_support/concern'

module TwitterUserPersistence
  extend ActiveSupport::Concern

  included do
    attr_accessor :copied_friend_uids, :copied_follower_uids, :copied_user_timeline, :copied_mention_tweets, :copied_favorite_tweets
  end

  def perform_before_transaction
    if copied_user_timeline&.is_a?(Array)
      InMemory::StatusTweet.import_from(uid, copied_user_timeline)
    end

    if copied_favorite_tweets&.is_a?(Array)
      InMemory::FavoriteTweet.import_from(uid, copied_favorite_tweets)
    end

    if copied_mention_tweets&.is_a?(Array)
      InMemory::MentionTweet.import_from(uid, copied_mention_tweets)
    end
  end

  def perform_after_commit
    InMemory::TwitterUser.import_from(id, uid, screen_name, profile_text, copied_friend_uids, copied_follower_uids)
    data = {
        id: id,
        uid: uid,
        screen_name: screen_name,
        profile: profile_text,
        friend_uids: copied_friend_uids,
        follower_uids: copied_follower_uids,
        status_tweets: copied_user_timeline,
        favorite_tweets: copied_favorite_tweets,
        mention_tweets: copied_mention_tweets,
    }
    data = Base64.encode64(Zlib::Deflate.deflate(data.to_json))
    PerformAfterCommitWorker.perform_async(id, data)
    CreateTwitterUserOneSidedFriendsWorker.perform_async(id)
  end
end
