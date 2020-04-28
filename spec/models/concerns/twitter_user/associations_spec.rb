require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Associations do
  let(:twitter_user) { create(:twitter_user) }

  describe '#friends' do
    it 'calls TwitterDB::User.where_and_order_by_field' do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: twitter_user.friend_uids)
      twitter_user.friends
    end

    it 'returns friends sorted by friend_uids' do
      expect(twitter_user.friends.map(&:uid)).to match_array(twitter_user.friend_uids)
    end
  end

  describe '#followers' do
    it 'calls TwitterDB::User.where_and_order_by_field' do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: twitter_user.follower_uids)
      twitter_user.followers
    end

    it 'returns followers sorted by friend_uids' do
      expect(twitter_user.followers.map(&:uid)).to match_array(twitter_user.follower_uids)
    end
  end

  describe '#status_tweets' do
    let(:tweets) { [{'id' => 1, 'text' => 'text1', 'raw_attrs_text' => '{}'}, {'id' => 2, 'text' => 'text2', 'raw_attrs_text' => '{}'}] }
    subject { twitter_user.status_tweets }

    context 'The record is new' do
      it do
        expect(Efs::StatusTweet).to receive(:where).with(uid: twitter_user.uid).and_return(tweets.map { |t| Efs::Tweet.new(t) })
        expect(S3::StatusTweet).not_to receive(:where)
        expect(subject.size).to eq(tweets.size)
      end
    end

    context 'The record is old' do
      before do
        twitter_user.update(created_at: (Efs::StatusTweet.client.ttl + 1.second).ago)
      end

      it do
        expect(Efs::StatusTweet).not_to receive(:where)
        expect(S3::StatusTweet).to receive(:where).with(uid: twitter_user.uid).and_return(tweets.map { |t| S3::Tweet.new(t) })
        expect(subject.size).to eq(tweets.size)
      end
    end
  end

  describe '#favorite_tweets' do
    let(:tweets) { [{'id' => 1, 'text' => 'text1', 'raw_attrs_text' => '{}'}, {'id' => 2, 'text' => 'text2', 'raw_attrs_text' => '{}'}] }
    subject { twitter_user.favorite_tweets }

    context 'The record is new' do
      it do
        expect(Efs::FavoriteTweet).to receive(:where).with(uid: twitter_user.uid).and_return(tweets.map { |t| Efs::Tweet.new(t) })
        expect(S3::FavoriteTweet).not_to receive(:where)
        expect(subject.size).to eq(tweets.size)
      end
    end

    context 'The record is old' do
      before do
        twitter_user.update(created_at: (Efs::FavoriteTweet.client.ttl + 1.second).ago)
      end

      it do
        expect(Efs::FavoriteTweet).not_to receive(:where)
        expect(S3::FavoriteTweet).to receive(:where).with(uid: twitter_user.uid).and_return(tweets.map { |t| S3::Tweet.new(t) })
        expect(subject.size).to eq(tweets.size)
      end
    end
  end

  describe '#mention_tweets' do
    let(:tweets) { [{'id' => 1, 'text' => 'text1', 'raw_attrs_text' => '{}'}, {'id' => 2, 'text' => 'text2', 'raw_attrs_text' => '{}'}] }
    subject { twitter_user.mention_tweets }

    context 'The record is new' do
      it do
        expect(Efs::MentionTweet).to receive(:where).with(uid: twitter_user.uid).and_return(tweets.map { |t| Efs::Tweet.new(t) })
        expect(S3::MentionTweet).not_to receive(:where)
        expect(subject.size).to eq(tweets.size)
      end
    end

    context 'The record is old' do
      before do
        twitter_user.update(created_at: (Efs::FavoriteTweet.client.ttl + 1.second).ago)
      end

      it do
        expect(Efs::MentionTweet).not_to receive(:where)
        expect(S3::MentionTweet).to receive(:where).with(uid: twitter_user.uid).and_return(tweets.map { |t| S3::Tweet.new(t) })
        expect(subject.size).to eq(tweets.size)
      end
    end
  end


  describe '#unfriendships' do
    before do
      Unfriendship.create!(from_uid: twitter_user.uid, friend_uid: 1, sequence: 0)
    end

    it do
      expect(twitter_user.unfriendships.pluck(:friend_uid)).to match_array([1])
    end
  end

  describe '#unfollowerships' do
    before do
      Unfollowership.create!(from_uid: twitter_user.uid, follower_uid: 1, sequence: 0)
    end

    it do
      expect(twitter_user.unfollowerships.pluck(:follower_uid)).to match_array([1])
    end
  end
end