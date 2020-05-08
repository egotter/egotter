require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  let(:twitter_user) { build(:twitter_user, with_relations: true) }
  let(:status_tweets) { twitter_user.instance_variable_get(:@reserved_statuses).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:favorite_tweets) { twitter_user.instance_variable_get(:@reserved_favorites).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:mention_tweets) { twitter_user.instance_variable_get(:@reserved_mentions).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }

  context 'after commit' do
    subject { twitter_user.save!(validate: false) }
    it do
      expect(twitter_user).to receive(:perform_after_commit)
      subject
    end
  end

  describe '#perform_after_commit' do
    let(:profile) { {dummy: true} }
    subject { twitter_user.perform_after_commit }
    before do
      twitter_user.id = 1
      twitter_user.uid = 2
      twitter_user.screen_name = 'sn'
      allow(twitter_user).to receive(:profile_text).and_return(profile.to_json)
      twitter_user.instance_variable_set(:@reserved_friend_uids, [1, 2])
      twitter_user.instance_variable_set(:@reserved_follower_uids, [3, 4])
    end

    context 'Efs' do
      it do
        expect(Efs::TwitterUser).to receive(:import_from!).with(1, 2, 'sn', profile.to_json, [1, 2], [3, 4])
        subject
      end

      it do
        expect(Efs::StatusTweet).to receive(:import_from!).with(2, 'sn', status_tweets)
        subject
      end

      it do
        expect(Efs::FavoriteTweet).to receive(:import_from!).with(2, 'sn', favorite_tweets)
        subject
      end

      it do
        expect(Efs::MentionTweet).to receive(:import_from!).with(2, 'sn', mention_tweets)
        subject
      end
    end

    context 'S3' do
      it do
        expect(S3::Friendship).to receive(:import_from!).with(1, 2, 'sn', [1, 2], async: true)
        subject
      end

      it do
        expect(S3::Followership).to receive(:import_from!).with(1, 2, 'sn', [3, 4], async: true)
        subject
      end

      it do
        expect(S3::Profile).to receive(:import_from!).with(1, 2, 'sn', profile.to_json, async: true)
        subject
      end

      it do
        expect(S3::StatusTweet).to receive(:import_from!).with(2, 'sn', status_tweets)
        subject
      end

      it do
        expect(S3::FavoriteTweet).to receive(:import_from!).with(2, 'sn', favorite_tweets)
        subject
      end

      it do
        expect(S3::MentionTweet).to receive(:import_from!).with(2, 'sn', mention_tweets)
        subject
      end
    end

    context 'InMemory' do
      it do
        expect(InMemory::StatusTweet).to receive(:import_from).with(2, status_tweets)
        subject
      end
    end

  end
end
