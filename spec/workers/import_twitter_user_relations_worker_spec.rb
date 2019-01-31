require 'rails_helper'

RSpec.describe ImportTwitterUserRelationsWorker do
  let(:twitter_user) { create(:twitter_user) }
  let(:instance) { described_class.new }
  let(:client) { ApiClient.instance }

  describe '#import_favorite_and_close_friendships' do
    subject { instance.import_favorite_and_close_friendships(client, twitter_user) }

    it 'calls FavoriteFriendship.import_by!' do
      expect(FavoriteFriendship).to receive(:import_by!).with(twitter_user: twitter_user).and_return([])
      subject
    end

    it 'calls CloseFriendship.import_by!' do
      allow(FavoriteFriendship).to receive(:import_by!).with(twitter_user: twitter_user).and_return([])
      expect(CloseFriendship).to receive(:import_by!).with(twitter_user: twitter_user).and_return([])
      subject
    end

    it 'calls #import_twitter_db_users' do
      allow(FavoriteFriendship).to receive(:import_by!).with(twitter_user: twitter_user).and_return([1])
      allow(CloseFriendship).to receive(:import_by!).with(twitter_user: twitter_user).and_return([2])
      expect(instance).to receive(:import_twitter_db_users).with(client, [1, 2])
      subject
    end
  end

  describe '#import_friendships' do
    subject { instance.import_friendships(twitter_user, friend_uids, follower_uids) }
    let(:friend_uids) { [1, 2, 3] }
    let(:follower_uids) { [2, 3, 4] }

    it 'calls Friendship.import_from!' do
      expect(Friendship).to receive(:import_from!).with(twitter_user.id, friend_uids)
      subject
    end

    it 'calls Followership.import_from!' do
      allow(Friendship).to receive(:import_from!).with(twitter_user.id, friend_uids)
      expect(Followership).to receive(:import_from!).with(twitter_user.id, follower_uids)
      subject
    end

    it 'Updates TwitterUser' do
      allow(Friendship).to receive(:import_from!).with(twitter_user.id, friend_uids)
      allow(Followership).to receive(:import_from!).with(twitter_user.id, follower_uids)
      expect(twitter_user).to receive(:update!).with(friends_size: friend_uids.size, followers_size: follower_uids.size)
      subject
    end
  end

  describe '#import_twitter_db_friendships' do
    subject { instance.import_twitter_db_friendships(client, twitter_user, friend_uids, follower_uids) }
    let(:friend_uids) { [1, 2, 3] }
    let(:follower_uids) { [2, 3, 4] }

    before { create(:twitter_db_user,  uid: twitter_user.uid) }

    it 'calls TwitterDB::Friendship.import_from!' do
      expect(TwitterDB::Friendship).to receive(:import_from!).with(twitter_user.uid, friend_uids)
      subject
    end

    it 'calls TwitterDB::Followership.import_from!' do
      allow(TwitterDB::Friendship).to receive(:import_from!).with(twitter_user.uid, friend_uids)
      expect(TwitterDB::Followership).to receive(:import_from!).with(twitter_user.uid, follower_uids)
      subject
    end

    it 'updates TwitterDB::User' do
      allow(TwitterDB::Friendship).to receive(:import_from!).with(twitter_user.uid, friend_uids)
      allow(TwitterDB::Followership).to receive(:import_from!).with(twitter_user.uid, follower_uids)
      subject
      TwitterDB::User.find_by(uid: twitter_user.uid).tap do |user|
        expect(user.friends_size).to eq(friend_uids.size)
        expect(user.followers_size).to eq(follower_uids.size)
      end
    end
  end

  describe '#import_other_relationships' do
    subject { instance.import_other_relationships(twitter_user) }

    it 'calls Xxx.import_by!' do
      [
          Unfriendship,
          Unfollowership,
          OneSidedFriendship,
          OneSidedFollowership,
          MutualFriendship,
          BlockFriendship,
          InactiveFriendship,
          InactiveFollowership,
          InactiveMutualFriendship
      ].each do |klass|
        expect(klass).to receive(:import_by!).with(twitter_user: twitter_user)
      end
      subject
    end
  end
end
