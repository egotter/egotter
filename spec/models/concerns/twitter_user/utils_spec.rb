require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Utils do
  describe '#friend_uids' do
    shared_context 'twitter_user is persisted' do
      before { twitter_user.save! }
    end

    let(:friend_uids) { [1, 2, 3] }
    let(:twitter_user) { build(:twitter_user) }
    subject { twitter_user.friend_uids }

    context 'twitter_user is not persisted' do
      before { twitter_user.instance_variable_set(:@reserved_friend_uids, 'hello') }
      it { is_expected.to eq('hello') }
    end

    context 'InMemory returns data' do
      include_context 'twitter_user is persisted'
      before { allow(InMemory::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('InMemory', friend_uids: friend_uids)) }
      it { is_expected.to match_array(friend_uids) }
    end

    context 'Efs returns data' do
      include_context 'twitter_user is persisted'
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('Efs', friend_uids: friend_uids))
      end
      it { is_expected.to match_array(friend_uids) }
    end

    context 'S3 returns data' do
      include_context 'twitter_user is persisted'
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs).to receive(:enabled?).and_return(false)
        allow(S3::Friendship).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(double('S3', friend_uids: friend_uids))
      end
      it { is_expected.to match_array(friend_uids) }
    end
  end

  describe '#follower_uids' do
    shared_context 'twitter_user is persisted' do
      before { twitter_user.save! }
    end

    let(:follower_uids) { [1, 2, 3] }
    let(:twitter_user) { build(:twitter_user) }
    subject { twitter_user.follower_uids }

    context 'twitter_user is not persisted' do
      before { twitter_user.instance_variable_set(:@reserved_follower_uids, 'hello') }
      it { is_expected.to eq('hello') }
    end

    context 'InMemory returns data' do
      include_context 'twitter_user is persisted'
      before { allow(InMemory::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('InMemory', follower_uids: follower_uids)) }
      it { is_expected.to match_array(follower_uids) }
    end

    context 'Efs returns data' do
      include_context 'twitter_user is persisted'
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('Efs', follower_uids: follower_uids))
      end
      it { is_expected.to match_array(follower_uids) }
    end

    context 'S3 returns data' do
      include_context 'twitter_user is persisted'
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs).to receive(:enabled?).and_return(false)
        allow(S3::Followership).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(double('S3', follower_uids: follower_uids))
      end
      it { is_expected.to match_array(follower_uids) }
    end
  end

  describe '#too_short_create_interval?' do
    let(:twitter_user) { build(:twitter_user) }
    let(:interval) { TwitterUser::CREATE_RECORD_INTERVAL }
    subject { twitter_user.too_short_create_interval? }

    before { twitter_user.save!(validate: false) }

    context 'The record was created more than [interval + 1 second] ago' do
      before { twitter_user.update!(created_at: (interval + 1).seconds.ago) }
      it { is_expected.to be_falsey }
    end

    context 'The record was created less than [interval - 1 second] ago' do
      before { twitter_user.update!(created_at: (interval - 1).seconds.ago) }
      it { is_expected.to be_truthy }
    end

    context 'The record was created [interval] ago' do
      before { twitter_user.update!(created_at: interval.seconds.ago) }
      it { is_expected.to be_falsey }
    end
  end
end
