require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  let(:twitter_user) { build(:twitter_user, id: rand(10000)) }
  let(:status_tweets) { twitter_user.statuses.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:favorite_tweets) { twitter_user.favorites.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:mention_tweets) { twitter_user.mentions.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  subject { twitter_user.save!(validate: false) }

  it do
    expect(Efs::TwitterUser).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.profile_text, twitter_user.friend_uids, twitter_user.follower_uids)

    expect(S3::Friendship).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.friend_uids, async: true)
    expect(S3::Followership).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.follower_uids, async: true)
    expect(S3::Profile).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.profile_text, async: true)

    expect(S3::StatusTweet).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, status_tweets)
    expect(S3::FavoriteTweet).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, favorite_tweets)
    expect(S3::MentionTweet).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, mention_tweets)

    subject
  end
end
