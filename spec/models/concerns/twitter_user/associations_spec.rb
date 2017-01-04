require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Associations do
  let(:twitter_user) { create(:twitter_user) }
  before do
    twitter_user
    [TwitterDB::Friendship, TwitterDB::Followership, TwitterDB::User].each { |klass| klass.delete_all }
    [Friendship, Followership].each { |klass| klass.delete_all }
    TwitterDB::User.import_from! ([twitter_user] + twitter_user.friends + twitter_user.followers)
  end

  describe '#tmp_friends' do
    it 'creates friendships and tmp_friends' do
      friendships = twitter_user.friends.map.with_index { |u, i| Friendship.new(from_id: twitter_user.id, friend_uid: u.uid, sequence: i) }
      expect(friendships.all? { |f| f.save! }).to be_truthy

      twitter_user.reload
      [twitter_user.friends.size, twitter_user.tmp_friends.size, friendships.size].combination(2) { |a, b| expect(a).to eq(b) }
      [twitter_user.friends.map(&:uid).map(&:to_i), twitter_user.tmp_friends.map(&:uid), friendships.map(&:friend_uid)].combination(2) { |a, b| expect(a).to eq(b) }
    end
  end

  describe '#tmp_followers' do
    it 'creates followerships and tmp_followers' do
      followerships = twitter_user.followers.map.with_index { |u, i| Followership.new(from_id: twitter_user.id, follower_uid: u.uid, sequence: i) }
      expect(followerships.all? { |f| f.save! }).to be_truthy

      twitter_user.reload
      [twitter_user.followers.size, twitter_user.tmp_followers.size, followerships.size].combination(2) { |a, b| expect(a).to eq(b) }
      [twitter_user.followers.map(&:uid).map(&:to_i), twitter_user.tmp_followers.map(&:uid), followerships.map(&:follower_uid)].combination(2) { |a, b| expect(a).to eq(b) }
    end
  end
end