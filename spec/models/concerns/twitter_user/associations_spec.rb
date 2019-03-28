require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Associations do
  let(:twitter_user) { create(:twitter_user) }

  describe '#friends' do
    it 'calls TwitterDB::User.where_and_order_by_field' do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: twitter_user.friend_uids)
      twitter_user.friends
    end

    it 'returns friends sorted by friend_uids' do
      expect(twitter_user.friends.map(&:uid)).to match_array(twitter_user.friend_uids)
    end
  end

  describe '#followers' do
    it 'calls TwitterDB::User.where_and_order_by_field' do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: twitter_user.follower_uids)
      twitter_user.followers
    end

    it 'returns followers sorted by friend_uids' do
      expect(twitter_user.followers.map(&:uid)).to match_array(twitter_user.follower_uids)
    end
  end

  describe '#unfriendships' do
    before do
      Unfriendship.create!(from_uid: twitter_user.uid, friend_uid: 1, sequence: 0)
    end

    it do
      expect(twitter_user.unfriendships.pluck(:friend_uid)).to match_array([1])
    end
  end

  describe '#unfollowerships' do
    before do
      Unfollowership.create!(from_uid: twitter_user.uid, follower_uid: 1, sequence: 0)
    end

    it do
      expect(twitter_user.unfollowerships.pluck(:follower_uid)).to match_array([1])
    end
  end
end