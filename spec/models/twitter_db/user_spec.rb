require 'rails_helper'

RSpec.describe TwitterDB::User, type: :model do
  context 'association' do
    let(:users) { 3.times.map { create(:twitter_db_user) } }
    let(:rest_users) { users - [users[0]] }

    describe '#friends' do
      it 'has many friends through friendships' do
        friendships = rest_users.map.with_index { |u, i| TwitterDB::Friendship.new(user_uid: users[0].uid, friend_uid: u.uid, sequence: i) }
        expect(friendships.all? { |f| f.save! }).to be_truthy

        expect(users[0].friends.size).to eq(friendships.size)
        expect(users[0].friends.map(&:uid)).to eq(friendships.map(&:friend_uid))
      end
    end

    describe '#followers' do
      it 'has many followers through followerships' do
        followerships = rest_users.map.with_index { |u, i| TwitterDB::Followership.new(user_uid: users[0].uid, follower_uid: u.uid, sequence: i) }
        expect(followerships.all? { |f| f.save! }).to be_truthy

        expect(users[0].followers.size).to eq(followerships.size)
        expect(users[0].followers.map(&:uid)).to eq(followerships.map(&:follower_uid))
      end
    end
  end

  describe '.import_each_slice' do
    let(:t_users) { 3.times.map { Hashie::Mash.new(id: rand(1000), screen_name: 'sn') } }
    let(:import_users) { t_users.map { |t_user| [t_user.id, t_user.screen_name, '{}', -1, -1] } }

    context 'with new records' do
      it 'creates all records' do
        expect { TwitterDB::User.import_each_slice(import_users) }.to change { TwitterDB::User.all.size }.by(import_users.size)
      end
    end

    context 'with persisted records' do
      before do
        t_user = t_users[0]
        TwitterDB::User.create!(uid: t_user.id, screen_name: t_user.screen_name, user_info: '{}', friends_size: -1, followers_size: -1)
      end
      it 'updates only changed records' do
        expect { TwitterDB::User.import_each_slice(import_users) }.to change { TwitterDB::User.all.size }.by(import_users.size - 1)
      end
    end
  end

  describe '.to_import_format' do
    let(:t_user) { Hashie::Mash.new(id: rand(1000), screen_name: 'sn') }
    it 'matches an array' do
      expect(TwitterDB::User.to_import_format(t_user)).to match([t_user.id, t_user.screen_name, {id: t_user.id, screen_name: t_user.screen_name}.to_json, -1, -1])
    end
  end

  describe '.to_save_format' do
    let(:t_user) { Hashie::Mash.new(id: rand(1000), screen_name: 'sn') }
    it 'matches a hash' do
      expect(TwitterDB::User.to_save_format(t_user)).to match({uid: t_user.id, screen_name: t_user.screen_name, user_info: {id: t_user.id, screen_name: t_user.screen_name}.to_json, friends_size: -1, followers_size: -1})
    end
  end

  describe '#persist!' do
    let(:uid) { rand(1000) }
    let(:generator) { Proc.new { Hashie::Mash.new(id: rand(10000), screen_name: 'sn') } }
    let(:t_user) { generator.call }
    let(:friends) { 3.times.map { generator.call } }
    let(:followers) { 2.times.map { generator.call } }
    let(:client) do
      client = Hashie::Mash.new(_fetch_parallelly: nil)
      allow(client).to receive(:_fetch_parallelly).and_return([t_user, friends, followers])
      client
    end
    let(:user) { TwitterDB::User.builder(uid).client(client).build }

    it 'saves TwitterDB::User' do
      expect { user.persist! }.to change { TwitterDB::User.all.size }.by(1 + friends.size + followers.size)
      user = TwitterDB::User.find_by(uid: self.user.uid)
      expect(user.friends_size).to eq(friends.size)
      expect(user.followers_size).to eq(followers.size)
    end

    it 'saves TwitterDB::Friendship' do
      expect { user.persist! }.to change { TwitterDB::Friendship.all.size }.by(friends.size)
    end

    it 'saves TwitterDB::Followership' do
      expect { user.persist! }.to change { TwitterDB::Followership.all.size }.by(followers.size)
    end

    context 'with persisted records' do
      before do
        friends[0].tap { |f| TwitterDB::User.create!(uid: f.id, screen_name: f.screen_name, user_info: '{}', friends_size: -1, followers_size: -1) }
      end

      it 'saves only new TwitterDB::User' do
        expect { user.persist! }.to change { TwitterDB::User.all.size }.by(1 + (friends.size - 1) + followers.size)
      end
    end
  end
end
