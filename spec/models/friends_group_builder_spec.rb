require 'rails_helper'

RSpec.describe FriendsGroupBuilder do
  let(:uid) { 1 }
  let(:limit) { 10 }
  let(:friend_uids1) { [1, 2, 3] }
  let(:follower_uids1) { [3, 4, 5] }
  let(:friend_uids2) { [3, 4, 5] }
  let(:follower_uids2) { [3, 4, 5] }
  let(:time) { Time.zone.now - 10.seconds }
  let(:users) { [TwitterUser.new(created_at: time + 1.second), TwitterUser.new(created_at: time + 2.second)] }
  let(:instance) { described_class.new(uid, limit: limit) }

  before do
    allow(users[0]).to receive(:friend_uids).and_return(friend_uids1)
    allow(users[0]).to receive(:follower_uids).and_return(follower_uids1)
    allow(users[1]).to receive(:friend_uids).and_return(friend_uids2)
    allow(users[1]).to receive(:follower_uids).and_return(follower_uids2)

    allow(described_class::Util).to receive(:users).with(uid, limit: limit).and_return(users)
  end

  describe '#friends' do
    subject { instance.friends }
    it { is_expected.to eq([friend_uids1, friend_uids2]) }
  end

  describe '#followers' do
    subject { instance.followers }
    it { is_expected.to eq([follower_uids1, follower_uids2]) }
  end

  describe '#new_friends' do
    subject { instance.new_friends }
    it { is_expected.to eq([friend_uids2 - friend_uids1]) }
  end

  describe '#new_followers' do
    subject { instance.new_followers }
    it { is_expected.to eq([follower_uids2 - follower_uids1]) }
  end

  describe '#unfriends' do

  end

  describe '#unfollowers' do

  end

  describe '#new_unfriends' do

  end

  describe '#new_unfollowers' do

  end
end

RSpec.describe FriendsGroupBuilder::Util do
  let(:older) { TwitterUser.new }
  let(:newer) { TwitterUser.new }

  before do
    allow(older).to receive(:friend_uids).with(no_args).and_return([1, 2, 3])
    allow(older).to receive(:follower_uids).with(no_args).and_return([4, 5, 6])

    if newer
      allow(newer).to receive(:friend_uids).with(no_args).and_return([2, 3, 4])
      allow(newer).to receive(:follower_uids).with(no_args).and_return([5, 6, 7])
    end
  end

  describe '.users' do
    let(:time) { Time.zone.now - 10.second }
    let(:uid) { 1 }
    let(:limit) { 2 }
    let(:users) { described_class.users(uid, limit: limit) }

    before do
      build(:twitter_user, uid: uid, created_at: time + 1.second).save!(validate: false)
      build(:twitter_user, uid: uid, created_at: time + 2.second).tap do |user|
        user.save!(validate: false)
        user.update(friends_size: 0)
      end
      build(:twitter_user, uid: uid, created_at: time + 3.second).save!(validate: false)
      build(:twitter_user, uid: uid, created_at: time + 4.second).save!(validate: false)
      create(:twitter_user, uid: uid + 1)
    end

    it do
      expect(users.size).to eq(2)
      expect(TwitterUser.find(users[0].id).created_at).to be < TwitterUser.find(users[1].id).created_at
    end
  end

  describe '.unfriends' do
    subject { described_class.unfriends(older, newer) }
    it do
      expect(UnfriendsBuilder::Util).to receive(:unfriends).with(older, newer)
      subject
    end
  end

  describe '.unfollowers' do
    subject { described_class.unfollowers(older, newer) }
    it do
      expect(UnfriendsBuilder::Util).to receive(:unfollowers).with(older, newer)
      subject
    end
  end

  describe '.new_friends' do
    subject { described_class.new_friends(older, newer) }
    it { is_expected.to match_array([4]) }

    context 'newer.nil? == true' do
      let(:newer) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '.new_followers' do
    subject { described_class.new_followers(older, newer) }
    it { is_expected.to match_array([7]) }

    context 'newer.nil? == true' do
      let(:newer) { nil }
      it { is_expected.to be_nil }
    end
  end
end
