require 'rails_helper'

RSpec.describe TwitterDB::User, type: :model do
  context 'association' do
    let(:users) { 3.times.map { TwitterDB::User.new(attributes_for(:twitter_db_user)) } }
    let(:user) { users[0] }
    let(:target) { users - [user] }
    before { users.each { |u| u.save! } }

    describe '#friends' do
      it 'creates friendships and friends' do
        friendships = target.map.with_index { |u, i| TwitterDB::Friendship.new(user_uid: user.uid, friend_uid: u.uid, sequence: i) }
        expect(friendships.all? { |f| f.save! }).to be_truthy

        user.reload
        expect(user.friends.size).to eq(friendships.size)
        expect(user.friends.map(&:uid)).to eq(friendships.map(&:friend_uid))
      end
    end

    describe '#followers' do
      it 'creates followerships and followers' do
        followerships = target.map.with_index { |u, i| TwitterDB::Followership.new(user_uid: user.uid, follower_uid: u.uid, sequence: i) }
        expect(followerships.all? { |f| f.save! }).to be_truthy

        user.reload
        expect(user.followers.size).to eq(followerships.size)
        expect(user.followers.map(&:uid)).to eq(followerships.map(&:follower_uid))
      end
    end
  end

  describe '.find_or_import_by' do
    let(:twitter_user) { create(:twitter_user) }
    before do
      twitter_user
      [TwitterDB::Friendship, TwitterDB::Followership, TwitterDB::User].each { |klass| klass.delete_all }
      [Friendship, Followership].each { |klass| klass.delete_all }
    end
    it 'creates passed record' do
      user = nil
      expect { user = TwitterDB::User.find_or_import_by(twitter_user) }.to change { TwitterDB::User.all.size }.by(1)
      expect(user.uid).to eq(twitter_user.uid.to_i)
    end
  end

  describe '.import_from!' do
    let(:twitter_users) { 3.times.map { create(:twitter_user) } }
    before do
      twitter_users
      [TwitterDB::Friendship, TwitterDB::Followership, TwitterDB::User].each { |klass| klass.delete_all }
      [Friendship, Followership].each { |klass| klass.delete_all }
    end

    context 'new records' do
      it 'creates all records' do
        expect { TwitterDB::User.import_from!(twitter_users) }.to change { TwitterDB::User.all.size }.by(twitter_users.size)
      end
    end

    context 'persisted records' do
      it 'updates only changed records' do
        expect(TwitterDB::User.create(attributes_for(:twitter_db_user, uid: twitter_users[0].uid))).to be_truthy
        expect { TwitterDB::User.import_from!(twitter_users) }.to change { TwitterDB::User.all.size }.by(twitter_users.size - 1)
      end
    end
  end
end
