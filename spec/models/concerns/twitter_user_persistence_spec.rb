require 'rails_helper'

RSpec.describe TwitterUserPersistence do
  let(:twitter_user) { build(:twitter_user) }

  describe '#perform_before_transaction' do
    subject { twitter_user.perform_before_transaction }
    before do
      twitter_user.copied_user_timeline = ['user_timeline']
      twitter_user.copied_favorite_tweets = ['favorite_tweets']
      twitter_user.copied_mention_tweets = ['mention_tweets']
    end
    it do
      expect(InMemory::StatusTweet).to receive(:import_from).with(twitter_user.uid, ['user_timeline'])
      expect(InMemory::FavoriteTweet).to receive(:import_from).with(twitter_user.uid, ['favorite_tweets'])
      expect(InMemory::MentionTweet).to receive(:import_from).with(twitter_user.uid, ['mention_tweets'])
      subject
    end
  end

  describe '#perform_after_commit' do
    subject { twitter_user.perform_after_commit }
    before { twitter_user.save! }
    it do
      expect(PerformAfterCommitWorker).to receive(:perform_async).with(twitter_user.id, anything)
      expect(CreateTwitterUserOneSidedFriendsWorker).to receive(:perform_async).with(twitter_user.id)
      subject
    end
  end
end
