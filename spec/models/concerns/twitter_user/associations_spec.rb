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
    shared_examples 'result matches return_data' do
      it do
        result = subject
        expect(result[0].uid).to eq(return_data[0].uid)
        expect(result[0].screen_name).to eq(return_data[0].screen_name)
        expect(result[0].raw_attrs_text).to eq(return_data[0].raw_attrs_text)
        expect(result[1].uid).to eq(return_data[1].uid)
        expect(result[1].screen_name).to eq(return_data[1].screen_name)
        expect(result[1].raw_attrs_text).to eq(return_data[1].raw_attrs_text)
      end
    end

    let(:return_data) do
      [
          double('tweet', uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: {text: 'text1'}.to_json),
          double('tweet', uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: {text: 'text2'}.to_json),
      ]
    end
    subject { twitter_user.status_tweets }

    context 'InMemory returns data' do
      before do
        allow(InMemory::StatusTweet).to receive(:find_by).with(twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::StatusTweet).to receive(:where).with(uid: twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::Tweet).to receive(:cache_alive?).with(anything).and_return(false)
        allow(S3::StatusTweet).to receive(:where).with(uid: twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end
  end

  describe '#favorite_tweets' do
    shared_examples 'result matches return_data' do
      it do
        result = subject
        expect(result[0].uid).to eq(return_data[0].uid)
        expect(result[0].screen_name).to eq(return_data[0].screen_name)
        expect(result[0].raw_attrs_text).to eq(return_data[0].raw_attrs_text)
        expect(result[1].uid).to eq(return_data[1].uid)
        expect(result[1].screen_name).to eq(return_data[1].screen_name)
        expect(result[1].raw_attrs_text).to eq(return_data[1].raw_attrs_text)
      end
    end

    let(:return_data) do
      [
          double('tweet', uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: {text: 'text1'}.to_json),
          double('tweet', uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: {text: 'text2'}.to_json),
      ]
    end
    subject { twitter_user.favorite_tweets }

    context 'InMemory returns data' do
      before do
        allow(InMemory::FavoriteTweet).to receive(:find_by).with(twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::FavoriteTweet).to receive(:where).with(uid: twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::Tweet).to receive(:cache_alive?).with(anything).and_return(false)
        allow(S3::FavoriteTweet).to receive(:where).with(uid: twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end
  end

  describe '#mention_tweets' do
    shared_examples 'result matches return_data' do
      it do
        result = subject
        expect(result[0].uid).to eq(return_data[0].uid)
        expect(result[0].screen_name).to eq(return_data[0].screen_name)
        expect(result[0].raw_attrs_text).to eq(return_data[0].raw_attrs_text)
        expect(result[1].uid).to eq(return_data[1].uid)
        expect(result[1].screen_name).to eq(return_data[1].screen_name)
        expect(result[1].raw_attrs_text).to eq(return_data[1].raw_attrs_text)
      end
    end

    let(:return_data) do
      [
          double('tweet', uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: {text: 'text1'}.to_json),
          double('tweet', uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: {text: 'text2'}.to_json),
      ]
    end
    subject { twitter_user.mention_tweets }

    context 'InMemory returns data' do
      before do
        allow(InMemory::MentionTweet).to receive(:find_by).with(twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::MentionTweet).to receive(:where).with(uid: twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
    end

    context 'Efs returns data' do
      before do
        allow(InMemory).to receive(:enabled?).and_return(false)
        allow(Efs::Tweet).to receive(:cache_alive?).with(anything).and_return(false)
        allow(S3::MentionTweet).to receive(:where).with(uid: twitter_user.uid).and_return(return_data)
      end

      include_examples('result matches return_data')
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