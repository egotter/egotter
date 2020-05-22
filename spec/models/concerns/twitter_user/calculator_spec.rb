require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Calculator do
  let(:twitter_user) { create(:twitter_user, with_relations: false) }
  let(:friend_uids) { [1, 2, 3] }
  let(:follower_uids) { [2, 3, 4] }

  before do
    allow(twitter_user).to receive(:friend_uids).and_return(friend_uids)
    allow(twitter_user).to receive(:follower_uids).and_return(follower_uids)
  end

  describe '#calc_uids_for' do
    subject { twitter_user.calc_uids_for(klass) }

    context 'S3::OneSidedFriendship is passed' do
      let(:klass) { S3::OneSidedFriendship }
      it do
        expect(twitter_user).to receive(:calc_one_sided_friend_uids)
        subject
      end
    end

    context 'S3::OneSidedFollowership is passed' do
      let(:klass) { S3::OneSidedFollowership }
      it do
        expect(twitter_user).to receive(:calc_one_sided_follower_uids)
        subject
      end
    end

    context 'S3::MutualFriendship is passed' do
      let(:klass) { S3::MutualFriendship }
      it do
        expect(twitter_user).to receive(:calc_mutual_friend_uids)
        subject
      end
    end

    context 'S3::InactiveFriendship is passed' do
      let(:klass) { S3::InactiveFriendship }
      it do
        expect(twitter_user).to receive(:calc_inactive_friend_uids)
        subject
      end
    end

    context 'S3::InactiveFollowership is passed' do
      let(:klass) { S3::InactiveFollowership }
      it do
        expect(twitter_user).to receive(:calc_inactive_follower_uids)
        subject
      end
    end

    context 'S3::InactiveMutualFriendship is passed' do
      let(:klass) { S3::InactiveMutualFriendship }
      it do
        expect(twitter_user).to receive(:calc_inactive_mutual_friend_uids)
        subject
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

  describe '#unfriends_builder' do
    subject { twitter_user.unfriends_builder }
    it do
      expect(UnfriendsBuilder).to receive(:new).with(twitter_user.uid, end_date: twitter_user.created_at).and_return('builder')
      is_expected.to eq('builder')
    end
  end

  describe '#calc_unfriend_uids' do
    let(:builder) { double('builder') }
    subject { twitter_user.calc_unfriend_uids }
    before { twitter_user.instance_variable_set(:@unfriends_builder, builder) }
    it do
      expect(builder).to receive_message_chain(:unfriends, :flatten)
      subject
    end
  end

  describe '#calc_unfollower_uids' do
    let(:builder) { double('builder') }
    subject { twitter_user.calc_unfollower_uids }
    before { twitter_user.instance_variable_set(:@unfriends_builder, builder) }
    it do
      expect(builder).to receive_message_chain(:unfollowers, :flatten)
      subject
    end
  end
end
