require 'rails_helper'

RSpec.describe TwitterUserAssociations do
  let(:twitter_user) { create(:twitter_user) }

  describe '#status_tweets' do
    subject { twitter_user.status_tweets }
    it do
      expect(twitter_user).to receive(:fetch_tweets).with(InMemory::StatusTweet, Efs::StatusTweet, S3::StatusTweet)
      subject
    end
  end

  describe '#favorite_tweets' do
    subject { twitter_user.favorite_tweets }
    it do
      expect(twitter_user).to receive(:fetch_tweets).with(InMemory::FavoriteTweet, Efs::FavoriteTweet, S3::FavoriteTweet)
      subject
    end
  end

  describe '#mention_tweets' do
    subject { twitter_user.mention_tweets }
    it do
      expect(twitter_user).to receive(:fetch_tweets).with(InMemory::MentionTweet, Efs::MentionTweet, S3::MentionTweet)
      subject
    end
  end

  describe '#fetch_tweets' do
    let(:memory_class) { InMemory::StatusTweet }
    let(:efs_class) { Efs::StatusTweet }
    let(:s3_class) { S3::StatusTweet }
    subject { twitter_user.send(:fetch_tweets, memory_class, efs_class, s3_class) }

    context 'InMemory returns data' do
      let(:wrapper) { memory_class.new(nil) }
      it do
        expect(memory_class).to receive(:find_by).with(twitter_user.uid).and_return(wrapper)
        expect(wrapper).to receive(:tweets)
        subject
      end
    end

    context 'Efs returns data' do
      let(:wrapper) { efs_class.new(nil) }
      before { allow(InMemory).to receive(:enabled?).and_return(false) }

      it do
        expect(efs_class).to receive(:find_by).with(twitter_user.uid).and_return(wrapper)
        expect(wrapper).to receive(:tweets)
        subject
      end
    end

    context 'S3 returns data' do
      let(:wrapper) { s3_class.new(nil) }
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::Tweet).to receive(:cache_alive?).with(twitter_user.created_at).and_return(false)
      end
      it do
        expect(s3_class).to receive(:find_by).with(twitter_user.uid).and_return(wrapper)
        expect(wrapper).to receive(:tweets)
        subject
      end
    end
  end
end
