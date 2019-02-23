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

  describe '#statuses' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index {|i| create(:twitter_db_status, uid: user.uid, screen_name: user.screen_name, sequence: i)} }
    it 'has many statuses' do
      expect(user.statuses.size).to eq(3)
    end
  end

  describe '.import_in_batches' do
    let(:t_users) { 3.times.map { Hashie::Mash.new(id: rand(1000000), screen_name: 'sn') } }
    let(:import_users) { t_users.map { |t_user| [t_user[:id], t_user[:screen_name], TwitterUser.collect_user_info(t_user), -1, -1] } }

    context 'with new records' do
      it 'creates all records' do
        expect { TwitterDB::User::Batch.import_in_batches(import_users) }.to change { TwitterDB::User.all.size }.by(import_users.size)
      end
    end

    context 'with new records and recently persisted records' do
      before do
        t_users[0].tap do |t_user|
          TwitterDB::User.create!(uid: t_user[:id], screen_name: t_user[:screen_name], user_info: TwitterUser.collect_user_info(t_user), friends_size: -1, followers_size: -1)
        end
      end
      it 'updates only new records' do
        expect { TwitterDB::User::Batch.import_in_batches(import_users) }.to change { TwitterDB::User.all.size }.by(import_users.size - 1)
      end
    end
  end

  describe '.import_by!' do
    let(:twitter_user) { build(:twitter_user) }
    subject { described_class.import_by!(twitter_user: twitter_user) }

    it 'Updates TwitterDB::User' do
      subject
      TwitterDB::User.find_by(uid: twitter_user.uid).tap do |user|
        expect(user.screen_name).to eq(twitter_user.screen_name)
        expect(user.friends_size).to eq(-1)
        expect(user.followers_size).to eq(-1)
        # TODO Check user_info
      end
    end
  end

  describe '.import_by' do
    let(:twitter_user) { build(:twitter_user) }
    subject { described_class.import_by(twitter_user: twitter_user) }

    it 'calls #import_by!' do
      expect(described_class).to receive(:import_by!).with(twitter_user: twitter_user)
      subject
    end

    it "doesn't raise an error" do
      allow(described_class).to receive(:import_by!).and_raise(StandardError)
      expect { subject }.to_not raise_error
    end
  end
end
