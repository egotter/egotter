require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  let(:twitter_user) { build(:twitter_user, with_relations: true, id: rand(10000)) }
  let(:status_tweets) { twitter_user.instance_variable_get(:@reserved_statuses).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:favorite_tweets) { twitter_user.instance_variable_get(:@reserved_favorites).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  let(:mention_tweets) { twitter_user.instance_variable_get(:@reserved_mentions).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) } }
  subject { twitter_user.save!(validate: false) }

  it do
    expect(Efs::TwitterUser).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.profile_text, twitter_user.friend_uids, twitter_user.follower_uids)
    subject
  end

  it do
    expect(DynamoDB::TwitterUser).to receive(:import_from).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.profile_text, twitter_user.friend_uids, twitter_user.follower_uids)
    subject
  end

  it do
    expect(S3::Friendship).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.friend_uids, async: true)
    subject
  end

  it do
    expect(S3::Followership).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.follower_uids, async: true)
    subject
  end

  it do
    expect(S3::Profile).to receive(:import_from!).
        with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, twitter_user.profile_text, async: true)
    subject
  end

  it do
    expect(S3::StatusTweet).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, status_tweets)
    subject
  end

  it do
    expect(S3::FavoriteTweet).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, favorite_tweets)
    subject
  end

  it do
    expect(S3::MentionTweet).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, mention_tweets)
    subject
  end
end
