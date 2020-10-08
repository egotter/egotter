require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  let(:user) { create(:twitter_user, with_relations: true) }
  let(:tweets) { [double('Tweet', raw_attrs_text: '{dummy: true}')] }

  describe '#status_tweets' do
    subject { user.status_tweets }
    before do
      allow(InMemory::StatusTweet).to receive(:find_by).with(user.uid)
      allow(Efs::StatusTweet).to receive(:where).with(uid: user.uid)
      allow(S3::StatusTweet).to receive(:where).with(uid: user.uid).and_return(tweets)
    end
    it { is_expected.to(satisfy) { |result| result.map(&:raw_attrs_text) == tweets.map(&:raw_attrs_text) } }
  end

  describe '#favorite_tweets' do
    subject { user.favorite_tweets }
    before do
      allow(InMemory::FavoriteTweet).to receive(:find_by).with(user.uid)
      allow(Efs::FavoriteTweet).to receive(:where).with(uid: user.uid)
      allow(S3::FavoriteTweet).to receive(:where).with(uid: user.uid).and_return(tweets)
    end
    it { is_expected.to(satisfy) { |result| result.map(&:raw_attrs_text) == tweets.map(&:raw_attrs_text) } }
  end

  describe '#mention_tweets' do
    subject { user.mention_tweets }
    before do
      allow(InMemory::MentionTweet).to receive(:find_by).with(user.uid)
      allow(Efs::MentionTweet).to receive(:where).with(uid: user.uid)
      allow(S3::MentionTweet).to receive(:where).with(uid: user.uid).and_return(tweets)
    end
    it { is_expected.to(satisfy) { |result| result.map(&:raw_attrs_text) == tweets.map(&:raw_attrs_text) } }
  end
end
