require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Associations do
  let(:twitter_user) { create(:twitter_user) }

  # These tests doesn't work in test environment because using `ActiveRecord::Base.connection.select_all`.

  describe '#friends' do
    pending 'returns friends sorted by sequence' do
      expect(twitter_user.friends.map(&:uid)).to match_array(twitter_user.friendships.map(&:friend_uid))
    end
  end

  describe '#followers' do
    pending 'returns followers sorted by sequence' do
      expect(twitter_user.followers.map(&:uid)).to match_array(twitter_user.followerships.map(&:follower_uid))
    end
  end

  describe '#unfriends' do
    pending 'returns unfriends sorted by sequence' do
      create(:twitter_user, uid: twitter_user.uid)
      expect(twitter_user.unfriends.map(&:uid)).to match_array(twitter_user.unfriendships.map(&:friend_uid))
    end
  end

  describe '#unfollowers' do
    pending 'returns unfollowers sorted by sequence' do
      create(:twitter_user, uid: twitter_user.uid)
      expect(twitter_user.unfollowers.map(&:uid)).to match_array(twitter_user.unfollowerships.map(&:follower_uid))
    end
  end
end