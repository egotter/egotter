require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Associations do
  let(:twitter_user) { create(:twitter_user) }

  before { twitter_user.update!(created_at: Time.zone.now - 1.hour, updated_at: Time.zone.now - 1.hour) }

  describe '#friends' do
    it 'returns friends sorted by sequence' do
      expect(twitter_user.friends.map(&:uid)).to match_array(twitter_user.friendships.map(&:friend_uid))
    end
  end

  describe '#followers' do
    it 'returns followers sorted by sequence' do
      expect(twitter_user.followers.map(&:uid)).to match_array(twitter_user.followerships.map(&:follower_uid))
    end
  end

  describe '#unfriends' do
    it 'returns unfriends sorted by sequence' do
      create(:twitter_user, uid: twitter_user.uid)
      expect(twitter_user.unfriends.map(&:uid)).to match_array(twitter_user.unfriendships.map(&:friend_uid))
    end
  end

  describe '#unfollowers' do
    it 'returns unfollowers sorted by sequence' do
      create(:twitter_user, uid: twitter_user.uid)
      expect(twitter_user.unfollowers.map(&:uid)).to match_array(twitter_user.unfollowerships.map(&:follower_uid))
    end
  end
end