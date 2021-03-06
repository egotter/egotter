require 'rails_helper'

RSpec.describe TwitterUserUtils do
  let(:twitter_user) { build(:twitter_user) }

  describe '#friend_uids' do
    subject { twitter_user.friend_uids }

    context 'twitter_user is new record' do
      it { expect { subject }.to raise_error(RuntimeError) }
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
      it { expect { subject }.to raise_error(RuntimeError) }
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
    subject { twitter_user.send(:fetch_friend_uids) }
    it do
      expect(twitter_user).to receive(:fetch_uids).with(:friend_uids, InMemory::TwitterUser, Efs::TwitterUser, S3::Friendship)
      subject
    end
  end

  describe '#fetch_follower_uids' do
    subject { twitter_user.send(:fetch_follower_uids) }
    it do
      expect(twitter_user).to receive(:fetch_uids).with(:follower_uids, InMemory::TwitterUser, Efs::TwitterUser, S3::Followership)
      subject
    end
  end

  describe '#fetch_uids' do
    let(:method_name) { :friend_uids }
    let(:memory_class) { InMemory::TwitterUser }
    let(:efs_class) { Efs::TwitterUser }
    let(:s3_class) { S3::Friendship }
    subject { twitter_user.send(:fetch_uids, method_name, memory_class, efs_class, s3_class) }
    before { twitter_user.save! }

    context 'InMemory returns data' do
      let(:wrapper) { memory_class.new({}) }
      it do
        expect(memory_class).to receive(:find_by).with(twitter_user.id).and_return(wrapper)
        expect(wrapper).to receive(method_name)
        subject
      end
    end

    context 'Efs returns data' do
      let(:wrapper) { efs_class.new({}) }
      before { allow(InMemory).to receive(:enabled?).and_return(false) }
      it do
        expect(efs_class).to receive(:find_by).with(twitter_user.id).and_return(wrapper)
        expect(wrapper).to receive(method_name)
        subject
      end
    end

    context 'S3 returns data' do
      let(:wrapper) { s3_class.new({}) }
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs).to receive(:enabled?).and_return(false)
      end
      it do
        expect(s3_class).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(wrapper)
        expect(wrapper).to receive(method_name)
        subject
      end
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
  end

  describe '.too_short_create_interval?' do
    subject { TwitterUser.too_short_create_interval?(twitter_user.uid) }
    before { twitter_user.save!(validate: false) }

    context 'The record was created 1 hour ago' do
      before { twitter_user.update!(created_at: 1.hour.ago) }
      it { is_expected.to be_falsey }
    end

    context 'The record was created 1 minute ago' do
      before { twitter_user.update!(created_at: 1.minute.ago) }
      it { is_expected.to be_truthy }
    end
  end
end
