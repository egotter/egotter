require 'rails_helper'

RSpec.describe TwitterUserAssociations do
  let(:twitter_user) { create(:twitter_user) }
  let(:uid) { twitter_user.uid }

  describe '#mutual_friendships' do
    subject { twitter_user.mutual_friendships }
    it do
      expect(S3::MutualFriendship).to receive(:where).with(uid: uid)
      expect(MutualFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#one_sided_friendships' do
    subject { twitter_user.one_sided_friendships }
    it do
      expect(S3::OneSidedFriendship).to receive(:where).with(uid: uid)
      expect(OneSidedFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#one_sided_followerships' do
    subject { twitter_user.one_sided_followerships }
    it do
      expect(S3::OneSidedFollowership).to receive(:where).with(uid: uid)
      expect(OneSidedFollowership).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#inactive_friendships' do
    subject { twitter_user.inactive_friendships }
    it do
      expect(S3::InactiveFriendship).to receive(:where).with(uid: uid)
      expect(InactiveFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#inactive_followerships' do
    subject { twitter_user.inactive_followerships }
    it do
      expect(S3::InactiveFollowership).to receive(:where).with(uid: uid)
      expect(InactiveFollowership).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#inactive_mutual_friendships' do
    subject { twitter_user.inactive_mutual_friendships }
    it do
      expect(S3::InactiveMutualFriendship).to receive(:where).with(uid: uid)
      expect(InactiveMutualFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#mutual_unfriendships' do
    subject { twitter_user.mutual_unfriendships }
    it do
      expect(S3::MutualUnfriendship).to receive(:where).with(uid: uid)
      expect(BlockFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#unfriendships' do
    subject { twitter_user.unfriendships }
    it do
      expect(S3::Unfriendship).to receive(:where).with(uid: uid)
      expect(Unfriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#unfollowerships' do
    subject { twitter_user.unfollowerships }
    it do
      expect(S3::Unfollowership).to receive(:where).with(uid: uid)
      expect(Unfollowership).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  [
      [:close_friends, :close_friend_uids],
      [:favorite_friends, :favorite_friend_uids],
      [:mutual_friends, :mutual_friend_uids],
      [:one_sided_friends, :one_sided_friend_uids],
      [:one_sided_followers, :one_sided_follower_uids],
      [:inactive_friends, :inactive_friend_uids],
      [:inactive_followers, :inactive_follower_uids],
      [:inactive_mutual_friends, :inactive_mutual_friend_uids],
      [:friends, :friend_uids],
      [:followers, :follower_uids],
      [:mutual_unfriends, :mutual_unfriend_uids],
      [:unfriends, :unfriend_uids],
      [:unfollowers, :unfollower_uids],
      [:blockers, :blocker_uids],
  ].each do |method_name, api_name|
    describe "##{method_name}" do
      let(:method) { method_name }
      let(:api) { api_name }
      let(:uids) { [1, 2, 3] }
      subject { twitter_user.send(method_name) }
      before { uids.map { |uid| create(:twitter_db_user, uid: uid) } }
      it do
        expect(twitter_user).to receive(api).and_return(uids)
        expect(subject.map(&:uid)).to eq(uids)
      end
    end
  end

  describe '#mutual_friend_uids' do
    subject { twitter_user.mutual_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:mutual_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#one_sided_friend_uids' do
    subject { twitter_user.one_sided_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:one_sided_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#one_sided_follower_uids' do
    subject { twitter_user.one_sided_follower_uids }
    it do
      expect(twitter_user).to receive_message_chain(:one_sided_followerships, :pluck).with(:follower_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#inactive_mutual_friend_uids' do
    subject { twitter_user.inactive_mutual_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:inactive_mutual_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#inactive_friend_uids' do
    subject { twitter_user.inactive_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:inactive_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#inactive_follower_uids' do
    subject { twitter_user.inactive_follower_uids }
    it do
      expect(twitter_user).to receive_message_chain(:inactive_followerships, :pluck).with(:follower_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#mutual_unfriend_uids' do
    subject { twitter_user.mutual_unfriend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:mutual_unfriendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#unfriend_uids' do
    subject { twitter_user.unfriend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:unfriendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#unfollower_uids' do
    subject { twitter_user.unfollower_uids }
    it do
      expect(twitter_user).to receive_message_chain(:unfollowerships, :pluck).with(:follower_uid).and_return('result')
      is_expected.to eq('result')
    end
  end
end
