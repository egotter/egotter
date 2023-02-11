require 'rails_helper'

RSpec.describe TwitterUserCalculator do
  let(:twitter_user) { create(:twitter_user, with_relations: false) }
  let(:friend_uids) { [1, 2, 3] }
  let(:follower_uids) { [2, 3, 4] }

  before do
    allow(twitter_user).to receive(:friend_uids).and_return(friend_uids)
    allow(twitter_user).to receive(:follower_uids).and_return(follower_uids)
  end

  describe '.calc_total_new_friend_uids' do
    let(:users) do
      [
          create(:twitter_user, created_at: 5.seconds.ago),
          create(:twitter_user, created_at: 3.seconds.ago),
          create(:twitter_user, created_at: 1.seconds.ago),
      ]
    end
    subject { TwitterUser.calc_total_new_friend_uids(users) }
    it do
      expect(users[1]).to receive(:calc_new_friend_uids).with(users[0]).and_return([1, 2])
      expect(users[2]).to receive(:calc_new_friend_uids).with(users[1]).and_return([2, 3])
      is_expected.to eq([3, 2, 2, 1])
    end
  end

  describe '.calc_total_new_follower_uids' do
    let(:users) do
      [
          create(:twitter_user, created_at: 5.seconds.ago),
          create(:twitter_user, created_at: 3.seconds.ago),
          create(:twitter_user, created_at: 1.seconds.ago),
      ]
    end
    subject { TwitterUser.calc_total_new_follower_uids(users) }
    it do
      expect(users[1]).to receive(:calc_new_follower_uids).with(users[0]).and_return([1, 2])
      expect(users[2]).to receive(:calc_new_follower_uids).with(users[1]).and_return([2, 3])
      is_expected.to eq([3, 2, 2, 1])
    end
  end

  describe '.calc_total_new_unfriend_uids' do
    let(:users) do
      [
          create(:twitter_user, created_at: 5.seconds.ago),
          create(:twitter_user, created_at: 3.seconds.ago),
          create(:twitter_user, created_at: 1.seconds.ago),
      ]
    end
    subject { TwitterUser.calc_total_new_unfriend_uids(users) }
    it do
      expect(users[1]).to receive(:calc_new_unfriend_uids).with(users[0]).and_return([1, 2])
      expect(users[2]).to receive(:calc_new_unfriend_uids).with(users[1]).and_return([2, 3])
      is_expected.to eq([3, 2, 2, 1])
    end
  end

  describe '.calc_total_new_unfollower_uids' do
    let(:users) do
      [
          create(:twitter_user, created_at: 5.seconds.ago),
          create(:twitter_user, created_at: 3.seconds.ago),
          create(:twitter_user, created_at: 1.seconds.ago),
      ]
    end
    subject { TwitterUser.calc_total_new_unfollower_uids(users) }
    it do
      expect(users[1]).to receive(:calc_new_unfollower_uids).with(users[0]).and_return([1, 2])
      expect(users[2]).to receive(:calc_new_unfollower_uids).with(users[1]).and_return([2, 3])
      is_expected.to eq([3, 2, 2, 1])
    end
  end

  describe '#calc_uids_for' do
    subject { twitter_user.calc_uids_for(klass) }

    [
        [S3::OneSidedFriendship, :calc_one_sided_friend_uids],
        [S3::OneSidedFollowership, :calc_one_sided_follower_uids],
        [S3::MutualFriendship, :calc_mutual_friend_uids],
        [S3::InactiveFriendship, :calc_inactive_friend_uids],
        [S3::InactiveFollowership, :calc_inactive_follower_uids],
        [S3::InactiveMutualFriendship, :calc_inactive_mutual_friend_uids],
        [S3::Unfriendship, :calc_unfriend_uids],
        [S3::Unfollowership, :calc_unfollower_uids],
    ].each do |klass_value, method_value|
      context "#{klass_value} is passed" do
        let(:klass) { klass_value }
        let(:method_name) { method_value }
        it do
          expect(twitter_user).to receive(method_name)
          subject
        end
      end
    end
  end

  describe '#update_counter_cache_for' do
    subject { twitter_user.update_counter_cache_for(klass, 'value') }

    [
        [S3::OneSidedFriendship, :one_sided_friends_size],
        [S3::OneSidedFollowership, :one_sided_followers_size],
        [S3::MutualFriendship, :mutual_friends_size],
        [S3::Unfriendship, :unfriends_size],
        [S3::Unfollowership, :unfollowers_size],
        [S3::MutualUnfriendship, :mutual_unfriends_size],
    ].each do |klass_value, key_value|
      context "#{klass_value} is passed" do
        let(:klass) { klass_value }
        let(:key) { key_value }
        it do
          expect(twitter_user).to receive(:update).with(key => 'value')
          subject
        end
      end
    end
  end

  describe '#calc_one_sided_friend_uids' do
    subject { twitter_user.calc_one_sided_friend_uids }
    it { is_expected.to match_array(friend_uids - follower_uids) }
  end

  describe '#calc_one_sided_follower_uids' do
    subject { twitter_user.calc_one_sided_follower_uids }
    it { is_expected.to match_array(follower_uids - friend_uids) }
  end

  describe '#calc_mutual_friend_uids' do
    subject { twitter_user.calc_mutual_friend_uids }
    it { is_expected.to match_array(friend_uids & follower_uids) }
  end

  describe '#calc_favorite_friend_uids' do
    subject { twitter_user.calc_favorite_friend_uids(uniq: uniq) }
    before do
      allow(twitter_user).to receive(:calc_favorite_uids).and_return([1, 1, 2, 3, 3, 3])
    end
    context 'With uniq: true' do
      let(:uniq) { true }
      it { is_expected.to match_array([3, 1, 2]) }
    end
    context 'With uniq: false' do
      let(:uniq) { false }
      it { is_expected.to match_array([1, 1, 2, 3, 3, 3]) }
    end
  end

  describe '#calc_close_friend_uids' do
    let(:user) { create(:user) }
    subject { twitter_user.calc_close_friend_uids(login_user: user) }

    before do
      allow(twitter_user).to receive(:replying_uids).with(uniq: false).and_return([1])
      allow(twitter_user).to receive(:replied_uids).with(uniq: false, login_user: user).and_return([2])
      allow(twitter_user).to receive(:calc_favorite_friend_uids).with(uniq: false).and_return([3])
    end

    it do
      expect(twitter_user).to receive(:sort_by_count_desc).with([1, 2, 3]).and_return([4])
      is_expected.to match_array(4)
    end
  end

  describe '#calc_inactive_friend_uids' do
    subject { twitter_user.calc_inactive_friend_uids }
    it do
      expect(twitter_user).to receive(:calc_inactive_friend_uids!).with(slice: 1000, threads: 0)
      subject
    end
  end

  describe '#calc_inactive_friend_uids!' do
    subject { twitter_user.calc_inactive_friend_uids! }
    before { allow(twitter_user).to receive(:friend_uids).and_return([1, 2, 3]) }
    it do
      expect(twitter_user).to receive(:fetch_inactive_uids).with([1, 2, 3], 1000, 0)
      subject
    end
  end

  describe '#calc_inactive_follower_uids' do
    subject { twitter_user.calc_inactive_follower_uids }
    it do
      expect(twitter_user).to receive(:calc_inactive_follower_uids!).with(slice: 1000, threads: 0)
      subject
    end
  end

  describe '#calc_inactive_follower_uids!' do
    subject { twitter_user.calc_inactive_follower_uids! }
    before { allow(twitter_user).to receive(:follower_uids).and_return([1, 2, 3]) }
    it do
      expect(twitter_user).to receive(:fetch_inactive_uids).with([1, 2, 3], 1000, 0)
      subject
    end
  end

  describe '#calc_inactive_mutual_friend_uids' do
    subject { twitter_user.calc_inactive_mutual_friend_uids }
    it do
      expect(twitter_user).to receive(:calc_inactive_mutual_friend_uids!).with(slice: 1000, threads: 0)
      subject
    end
  end

  describe '#calc_inactive_mutual_friend_uids!' do
    subject { twitter_user.calc_inactive_mutual_friend_uids! }
    before { allow(twitter_user).to receive(:mutual_friend_uids).and_return([1, 2, 3]) }
    it do
      expect(twitter_user).to receive(:fetch_inactive_uids).with([1, 2, 3], 1000, 0)
      subject
    end
  end

  describe '#fetch_inactive_uids' do
    let(:uids) { [1, 2, 3] }
    let(:slice) { 1000 }
    subject { twitter_user.fetch_inactive_uids(uids, slice, 0) }
    it do
      expect(twitter_user).to receive(:fetch_inactive_uids_direct).with([1, 2, 3], 1000)
      subject
    end

    context 'threads is 2' do
      let(:uids) { (1..1001).to_a }
      subject { twitter_user.fetch_inactive_uids(uids, slice, 2) }
      it do
        expect(twitter_user).to receive(:fetch_inactive_uids_in_threads).with(uids, 1000, 2)
        subject
      end
    end
  end

  describe '#fetch_inactive_uids_in_threads' do
    before do
      create(:twitter_db_user, uid: 1, status_created_at: 1.days.ago)
      create(:twitter_db_user, uid: 2, status_created_at: 15.days.ago)
      create(:twitter_db_user, uid: 3, status_created_at: 1.days.ago)
      create(:twitter_db_user, uid: 4, status_created_at: 15.days.ago)
      create(:twitter_db_user, uid: 5, status_created_at: 1.days.ago)
    end
    subject { twitter_user.fetch_inactive_uids_in_threads([1, 2, 3, 4, 5], 2, 2) }
    it { is_expected.to eq([2, 4]) }
  end

  describe '#fetch_inactive_uids_direct' do
    before do
      create(:twitter_db_user, uid: 1, status_created_at: 1.days.ago)
      create(:twitter_db_user, uid: 2, status_created_at: 15.days.ago)
      create(:twitter_db_user, uid: 3, status_created_at: 1.days.ago)
      create(:twitter_db_user, uid: 4, status_created_at: 15.days.ago)
      create(:twitter_db_user, uid: 5, status_created_at: 1.days.ago)
    end
    subject { twitter_user.fetch_inactive_uids_direct([1, 2, 3, 4, 5], 3) }
    it { is_expected.to eq([2, 4]) }
  end

  describe '#calc_unfriend_uids' do
    subject { twitter_user.calc_unfriend_uids }
    before { allow(twitter_user).to receive(:unfriends_target).and_return('target') }
    it do
      expect(TwitterUser).to receive(:calc_total_new_unfriend_uids).with('target')
      subject
    end
  end

  describe '#calc_unfollower_uids' do
    subject { twitter_user.calc_unfollower_uids }
    before { allow(twitter_user).to receive(:unfriends_target).and_return('target') }
    it do
      expect(TwitterUser).to receive(:calc_total_new_unfollower_uids).with('target')
      subject
    end
  end

  describe '#calc_mutual_unfriend_uids' do
    subject { twitter_user.calc_mutual_unfriend_uids }
    before do
      allow(twitter_user).to receive(:calc_unfriend_uids).and_return([1, 2, 3])
      allow(twitter_user).to receive(:calc_unfollower_uids).and_return([2, 3, 4])
    end
    it { is_expected.to eq([2, 3]) }
  end

  describe '#calc_new_friend_uids' do
    subject { twitter_user.calc_new_friend_uids }
    before do
      record = build(:twitter_user, uid: twitter_user.uid)
      allow(record).to receive(:friend_uids).and_return([1, 2])
      allow(twitter_user).to receive(:previous_version).and_return(record)
    end
    it { is_expected.to eq([3]) }
  end

  describe '#calc_new_follower_uids' do
    subject { twitter_user.calc_new_follower_uids }
    before do
      record = build(:twitter_user, uid: twitter_user.uid)
      allow(record).to receive(:follower_uids).and_return([2, 3])
      allow(twitter_user).to receive(:previous_version).and_return(record)
    end
    it { is_expected.to eq([4]) }
  end

  describe '#calc_new_unfriend_uids' do
    subject { twitter_user.calc_new_unfriend_uids }
    before do
      record = build(:twitter_user, uid: twitter_user.uid)
      allow(record).to receive(:friend_uids).and_return([1, 2, 3, 4])
      allow(twitter_user).to receive(:previous_version).and_return(record)
    end
    it { is_expected.to eq([4]) }
  end

  describe '#calc_new_unfollower_uids' do
    subject { twitter_user.calc_new_unfollower_uids }
    before do
      record = build(:twitter_user, uid: twitter_user.uid)
      allow(record).to receive(:follower_uids).and_return([2, 3, 4, 5])
      allow(twitter_user).to receive(:previous_version).and_return(record)
    end
    it { is_expected.to eq([5]) }
  end

  describe '#previous_version' do
    let(:record1) { build(:twitter_user, uid: twitter_user.uid, created_at: twitter_user.created_at - 1.hour) }
    let(:record2) { build(:twitter_user, uid: twitter_user.uid, created_at: twitter_user.created_at + 1.hour) }
    subject { twitter_user.send(:previous_version) }
    before do
      record1.save(validate: false)
      record2.save(validate: false)
    end
    it { expect(subject.id).to eq(record1.id) }
  end

  describe '#unfriends_target_cache' do
    let(:users) { [create(:twitter_user), create(:twitter_user)] }
    subject { twitter_user.send(:unfriends_target_cache) }
    before { allow(twitter_user).to receive(:unfriends_target).and_return(users) }
    it { expect(subject.size).to eq(2) }
  end
end
