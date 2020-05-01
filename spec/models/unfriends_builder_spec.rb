require 'rails_helper'

RSpec.describe UnfriendsBuilder do
  describe '#unfriends' do

  end

  describe '#unfollowers' do

  end
end

RSpec.describe UnfriendsBuilder::Util do
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

  def users(uid, created_at)
    TwitterUser.where('created_at <= ?', created_at).creation_completed.where(uid: uid).select(:id).order(created_at: :asc)
  end

  describe '.users' do
    let(:time) { Time.zone.now - 10.second }
    let(:uid) { 1 }
    let(:limit) { 2 }
    let(:users) { described_class.users(uid, nil, @user.created_at) }

    before do
      build(:twitter_user, uid: uid, created_at: time + 1.second).save!(validate: false)
      build(:twitter_user, uid: uid, created_at: time + 2.second).tap do |user|
        user.save!(validate: false)
        user.update(friends_size: 0, followers_size: 0)
      end
      (@user = build(:twitter_user, uid: uid, created_at: time + 3.second)).save!(validate: false)
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
    it { is_expected.to match_array([1]) }

    context 'newer.nil? == true' do
      let(:newer) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '.unfollowers' do
    subject { described_class.unfollowers(older, newer) }
    it { is_expected.to match_array([4]) }

    context 'newer.nil? == true' do
      let(:newer) { nil }
      it { is_expected.to be_nil }
    end
  end
end
