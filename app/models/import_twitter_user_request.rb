# == Schema Information
#
# Table name: import_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  user_id         :integer          not null
#  twitter_user_id :integer          not null
#  finished_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_import_twitter_user_requests_on_created_at  (created_at)
#  index_import_twitter_user_requests_on_user_id     (user_id)
#

class ImportTwitterUserRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user, optional: true
  belongs_to :twitter_user

  validates :user_id, presence: true
  validates :twitter_user_id, presence: true

  def perform!
    uids = FavoriteFriendship.import_by(twitter_user: twitter_user)
    TwitterDB::User::Batch.fetch_and_import(uids, client: client)

    uids = CloseFriendship.import_by(twitter_user: twitter_user, login_user: user)
    TwitterDB::User::Batch.fetch_and_import(uids, client: client)

    return if twitter_user.no_need_to_import_friendships?

    uids = [twitter_user.uid] + twitter_user.friend_uids + twitter_user.follower_uids
    TwitterDB::User::Batch.fetch_and_import(uids, client: client)

    Unfriendship.import_by(twitter_user: twitter_user)
    Unfollowership.import_by(twitter_user: twitter_user)
    OneSidedFriendship.import_by(twitter_user: twitter_user)
    OneSidedFollowership.import_by(twitter_user: twitter_user)
    MutualFriendship.import_by(twitter_user: twitter_user)
    BlockFriendship.import_by(twitter_user: twitter_user)
    InactiveFriendship.import_by(twitter_user: twitter_user)
    InactiveFollowership.import_by(twitter_user: twitter_user)
    InactiveMutualFriendship.import_by(twitter_user: twitter_user)
  end

  def client
    if instance_variable_defined?(:@client)
      @client
    else
      @client = user ? user.api_client : Bot.api_client
    end
  end
end
