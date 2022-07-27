require 'rails_helper'

RSpec.describe PerformAfterCommitWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:twitter_user) { create(:twitter_user) }
    let(:id) { twitter_user.id }
    let(:uid) { twitter_user.uid }
    let(:screen_name) { 'name' }
    let(:profile) { 'profile' }
    let(:friend_uids) { 'uids1' }
    let(:follower_uids) { 'uids2' }
    let(:status_tweets) { ['status_tweets'] }
    let(:favorite_tweets) { ['favorite_tweets'] }
    let(:mention_tweets) { ['favorite_tweets'] }
    let(:data) do
      hash = {
          id: id,
          uid: uid,
          screen_name: screen_name,
          profile: profile,
          friend_uids: friend_uids,
          follower_uids: follower_uids,
          status_tweets: status_tweets,
          favorite_tweets: favorite_tweets,
          mention_tweets: mention_tweets
      }
      Base64.encode64(Zlib::Deflate.deflate(hash.to_json))
    end

    subject { worker.perform(id, data) }
    it do
      expect(WriteEfsTwitterUserWorker).to receive(:perform_async).
          with({twitter_user_id: id, uid: uid, screen_name: screen_name, profile: profile, friend_uids: friend_uids, follower_uids: follower_uids}, twitter_user_id: id)

      # expect(S3::Friendship).to receive(:import_from!).with(id, uid, screen_name, friend_uids, async: true)
      expect(WriteS3FriendshipWorker).to receive(:perform_async).
          with({twitter_user_id: id, uid: uid, screen_name: screen_name, friend_uids: friend_uids}, twitter_user_id: id)

      # expect(S3::Followership).to receive(:import_from!).with(id, uid, screen_name, follower_uids, async: true)
      expect(WriteS3FollowershipWorker).to receive(:perform_async).
          with({twitter_user_id: id, uid: uid, screen_name: screen_name, follower_uids: follower_uids}, twitter_user_id: id)

      # expect(S3::Profile).to receive(:import_from!).with(id, uid, screen_name, profile, async: true)
      expect(WriteS3ProfileWorker).to receive(:perform_async).
          with({twitter_user_id: id, uid: uid, screen_name: screen_name, profile: profile}, twitter_user_id: id)

      expect(S3::StatusTweet).to receive(:import_from!).with(uid, screen_name, status_tweets)
      expect(S3::FavoriteTweet).to receive(:import_from!).with(uid, screen_name, favorite_tweets)
      expect(S3::MentionTweet).to receive(:import_from!).with(uid, screen_name, mention_tweets)
      subject
    end
  end
end
