require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Associations do
  let(:twitter_user) { create(:twitter_user) }

  before do
    twitter_user.reload
    twitter_user.update!(created_at: Time.zone.now - 1.hour, updated_at: Time.zone.now - 1.hour)
  end

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

  describe '#unfriendships' do
    let(:copy1) { copy_twitter_user(twitter_user) }
    let(:copy2) { copy_twitter_user(copy1) }

    before { copy2.friendships.last.delete }

    it 'returns one uid' do
      expect(copy1.unfriendship_uids.size).to eq(0)
      expect(copy2.unfriendship_uids.size).to eq(1)
    end
  end

  describe '#unfollowerships' do
    let(:copy1) { copy_twitter_user(twitter_user) }
    let(:copy2) { copy_twitter_user(copy1) }

    before { copy2.followerships.last.delete }

    it 'returns one uid' do
      expect(copy1.unfollowership_uids.size).to eq(0)
      expect(copy2.unfollowership_uids.size).to eq(1)
    end
  end
end