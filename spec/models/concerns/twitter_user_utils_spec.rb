require 'rails_helper'

RSpec.describe Concerns::TwitterUserUtils do
  let(:twitter_user) { build(:twitter_user) }

  describe '#friend_uids' do
    subject { twitter_user.friend_uids }

    context 'twitter_user is new record' do
      before { twitter_user.instance_variable_set(:@reserved_friend_uids, 'result') }
      it { is_expected.to eq('result') }
    end

    context 'twitter_user is persisted' do
      before do
        twitter_user.save!
        twitter_user.instance_variable_set(:@persisted_friend_uids, 'result')
      end
      it { is_expected.to eq('result') }
    end
  end

  describe '#follower_uids' do
    subject { twitter_user.follower_uids }

    context 'twitter_user is new record' do
      before { twitter_user.instance_variable_set(:@reserved_follower_uids, 'result') }
      it { is_expected.to eq('result') }
    end

    context 'twitter_user is persisted' do
      before do
        twitter_user.save!
        twitter_user.instance_variable_set(:@persisted_follower_uids, 'result')
      end
      it { is_expected.to eq('result') }
    end
  end

  describe '#fetch_friend_uids' do
    let(:friend_uids) { 'result' }
    subject { twitter_user.send(:fetch_friend_uids) }
    before { twitter_user.save! }

    context 'InMemory returns data' do
      before { allow(InMemory::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('InMemory', friend_uids: friend_uids)) }
      it { is_expected.to eq(friend_uids) }
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('Efs', friend_uids: friend_uids))
      end
      it { is_expected.to eq(friend_uids) }
    end

    context 'S3 returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs).to receive(:enabled?).and_return(false)
        allow(S3::Friendship).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(double('S3', friend_uids: friend_uids))
      end
      it { is_expected.to eq(friend_uids) }
    end
  end

  describe '#fetch_follower_uids' do
    let(:follower_uids) { 'result' }
    subject { twitter_user.send(:fetch_follower_uids) }
    before { twitter_user.save! }

    context 'InMemory returns data' do
      before { allow(InMemory::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('InMemory', follower_uids: follower_uids)) }
      it { is_expected.to eq(follower_uids) }
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(double('Efs', follower_uids: follower_uids))
      end
      it { is_expected.to eq(follower_uids) }
    end

    context 'S3 returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs).to receive(:enabled?).and_return(false)
        allow(S3::Followership).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(double('S3', follower_uids: follower_uids))
      end
      it { is_expected.to eq(follower_uids) }
    end
  end

  describe '#too_short_create_interval?' do
    subject { twitter_user.too_short_create_interval? }

    before { twitter_user.save!(validate: false) }

    context 'The record was created 1 day ago' do
      before { twitter_user.update!(created_at: 1.day.ago) }
      it { is_expected.to be_falsey }
    end

    context 'The record was created 1 minute ago' do
      before { twitter_user.update!(created_at: 1.minute.ago) }
      it { is_expected.to be_truthy }
    end

    context 'The record was created [interval] ago' do
      before { twitter_user.update!(created_at: TwitterUser::CREATE_RECORD_INTERVAL.ago) }
      it { is_expected.to be_falsey }
    end
  end
end
