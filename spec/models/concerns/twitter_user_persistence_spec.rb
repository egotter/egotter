require 'rails_helper'

RSpec.describe TwitterUserPersistence do
  let(:twitter_user) { build(:twitter_user) }

  context 'Callbacks' do
    context 'After create' do
      subject { twitter_user.save!(validate: false) }
      it do
        expect(twitter_user).to receive(:perform_before_commit)
        expect(twitter_user).to receive(:perform_after_commit)
        subject
        expect(twitter_user.persisted?).to be_truthy
      end
    end

    context 'After update' do
      subject { twitter_user.update!(uid: twitter_user.uid + 1) }
      before { twitter_user.save!(validate: false) }
      it do
        expect(twitter_user).not_to receive(:perform_before_commit)
        expect(twitter_user).not_to receive(:perform_after_commit)
        subject
      end
    end
  end

  describe '#perform_before_transaction!' do
    subject { twitter_user.perform_before_transaction! }
    before do
      twitter_user.copied_user_timeline = 'ut'
      twitter_user.copied_favorite_tweets = 'ft'
      twitter_user.copied_mention_tweets = 'mt'
    end
    it do
      expect(InMemory::StatusTweet).to receive(:import_from).with(twitter_user.uid, 'ut')
      expect(InMemory::FavoriteTweet).to receive(:import_from).with(twitter_user.uid, 'ft')
      expect(InMemory::MentionTweet).to receive(:import_from).with(twitter_user.uid, 'mt')
      subject
    end
  end

  describe '#perform_before_commit' do
    subject { twitter_user.perform_before_commit }

    before do
      twitter_user.save!(validate: false)
      twitter_user.copied_friend_uids = 'uids1'
      twitter_user.copied_follower_uids = 'uids2'
      twitter_user.profile_text = 'pt'
    end

    it do
      values = twitter_user.slice(:id, :uid, :screen_name, :profile_text, :copied_friend_uids, :copied_follower_uids).values
      expect(InMemory::TwitterUser).to receive(:import_from).with(*values)
      subject
    end

    context 'an exception is raised' do
      before { allow(InMemory::TwitterUser).to receive(:import_from).with(any_args).and_raise('failed') }
      it { expect { subject }.to raise_error(ActiveRecord::Rollback) }
    end
  end

  describe '#perform_after_commit' do
    subject { twitter_user.perform_after_commit }
    it do
      expect(PerformAfterCommitWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end
end
