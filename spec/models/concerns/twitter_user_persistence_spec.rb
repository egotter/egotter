require 'rails_helper'

RSpec.describe TwitterUserPersistence do
  let(:twitter_user) { build(:twitter_user, with_relations: true) }

  let(:status_tweets) { 2.times.map { build(:twitter_db_status).slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:favorite_tweets) { 2.times.map { build(:twitter_db_status).slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:mention_tweets) { 2.times.map { build(:twitter_db_status).slice(:uid, :screen_name, :raw_attrs_text) } }

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

  describe '#perform_before_commit' do
    let(:profile) { {dummy: true} }
    subject { twitter_user.perform_before_commit }

    before do
      Redis.client.flushdb
      allow(twitter_user).to receive(:profile_text).and_return(profile.to_json)
      twitter_user.id = 1
      twitter_user.copied_friend_uids = [1, 2]
      twitter_user.copied_follower_uids = [3, 4]

      twitter_user.copied_user_timeline = status_tweets
      twitter_user.copied_favorite_tweets = favorite_tweets
      twitter_user.copied_mention_tweets = mention_tweets
    end

    context 'InMemory::TwitterUser' do
      it do
        expect(InMemory::TwitterUser).to receive(:import_from).
            with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, profile.to_json, [1, 2], [3, 4])
        subject
      end

      it do
        subject
        result = InMemory::TwitterUser.find_by(twitter_user.id)
        expect(result).not_to be_nil
        expect(result.uid).to eq(twitter_user.uid)
        expect(result.screen_name).to eq(twitter_user.screen_name)
        expect(result.profile.to_json).to eq(profile.to_json)
        expect(result.friend_uids).to eq([1, 2])
        expect(result.follower_uids).to eq([3, 4])
      end
    end

    context 'InMemory::StatusTweet' do
      it do
        expect(InMemory::StatusTweet).to receive(:import_from).with(twitter_user.uid, status_tweets)
        subject
      end

      it do
        subject
        tweets = InMemory::StatusTweet.find_by(twitter_user.uid)
        expect(tweets.size).to eq(status_tweets.size)
        tweets.each.with_index do |tweet, i|
          expect(tweet.raw_attrs_text).to eq(status_tweets[i][:raw_attrs_text])
        end
      end
    end

    context 'InMemory::FavoriteTweet' do
      it do
        expect(InMemory::FavoriteTweet).to receive(:import_from).with(twitter_user.uid, favorite_tweets)
        subject
      end

      it do
        subject
        tweets = InMemory::FavoriteTweet.find_by(twitter_user.uid)
        tweets.each.with_index do |tweet, i|
          expect(tweet.raw_attrs_text).to eq(favorite_tweets[i][:raw_attrs_text])
        end
      end
    end

    context 'InMemory::MentionTweet' do
      it do
        expect(InMemory::MentionTweet).to receive(:import_from).with(twitter_user.uid, mention_tweets)
        subject
      end

      it do
        subject
        tweets = InMemory::MentionTweet.find_by(twitter_user.uid)
        tweets.each.with_index do |tweet, i|
          expect(tweet.raw_attrs_text).to eq(mention_tweets[i][:raw_attrs_text])
        end
      end
    end

    context 'an exception is raised' do
      subject { twitter_user.save!(validate: false) }
      before { allow(InMemory::TwitterUser).to receive(:import_from).with(any_args).and_raise('failed') }
      it do
        expect(twitter_user).to receive(:perform_before_commit).and_call_original
        expect(twitter_user).not_to receive(:perform_after_commit)
        subject
        expect(twitter_user.persisted?).to be_falsey
      end
    end
  end
end
