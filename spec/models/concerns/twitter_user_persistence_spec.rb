require 'rails_helper'

RSpec.describe TwitterUserPersistence do
  let(:twitter_user) { build(:twitter_user, with_relations: true) }
  let(:status_tweets) { twitter_user.instance_variable_get(:@reserved_statuses).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:favorite_tweets) { twitter_user.instance_variable_get(:@reserved_favorites).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:mention_tweets) { twitter_user.instance_variable_get(:@reserved_mentions).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }

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
      twitter_user.instance_variable_set(:@reserved_friend_uids, [1, 2])
      twitter_user.instance_variable_set(:@reserved_follower_uids, [3, 4])
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

  describe '#perform_after_commit' do
    let(:profile) { {dummy: true} }
    subject { twitter_user.perform_after_commit }

    before do
      allow(twitter_user).to receive(:profile_text).and_return(profile.to_json)
      twitter_user.id = 1
      twitter_user.instance_variable_set(:@reserved_friend_uids, [1, 2])
      twitter_user.instance_variable_set(:@reserved_follower_uids, [3, 4])
    end

    context 'Efs' do
      before do
        Efs::TwitterUser.cache_client.clear
        Efs::StatusTweet.client.instance_variable_get(:@efs).clear
        Efs::FavoriteTweet.client.instance_variable_get(:@efs).clear
        Efs::MentionTweet.client.instance_variable_get(:@efs).clear
      end

      context 'TwitterUser' do
        it do
          expect(Efs::TwitterUser).to receive(:import_from!).
              with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, profile.to_json, [1, 2], [3, 4])
          subject
        end

        it do
          subject
          result = Efs::TwitterUser.find_by(twitter_user.id)
          expect(result).not_to be_nil
          expect(result.uid).to eq(twitter_user.uid)
          expect(result.screen_name).to eq(twitter_user.screen_name)
          expect(result.profile.to_json).to eq(profile.to_json)
          expect(result.friend_uids).to eq([1, 2])
          expect(result.follower_uids).to eq([3, 4])
        end
      end
    end

    context 'S3' do
      it do
        expect(S3::Friendship).to receive(:import_from!).
            with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, [1, 2], async: true)
        subject
      end

      it do
        expect(S3::Followership).to receive(:import_from!).
            with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, [3, 4], async: true)
        subject
      end

      it do
        expect(S3::Profile).to receive(:import_from!).
            with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, profile.to_json, async: true)
        subject
      end

      it do
        expect(S3::StatusTweet).to receive(:import_from!).
            with(twitter_user.uid, twitter_user.screen_name, status_tweets)
        subject
      end

      it do
        expect(S3::FavoriteTweet).to receive(:import_from!).
            with(twitter_user.uid, twitter_user.screen_name, favorite_tweets)
        subject
      end

      it do
        expect(S3::MentionTweet).to receive(:import_from!).
            with(twitter_user.uid, twitter_user.screen_name, mention_tweets)
        subject
      end
    end

  end
end
