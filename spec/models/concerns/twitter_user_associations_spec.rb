require 'rails_helper'

RSpec.describe Concerns::TwitterUserAssociations do
  let(:twitter_user) { create(:twitter_user) }
  let(:uid) { twitter_user.uid }

  describe '#mutual_friendships' do
    subject { twitter_user.mutual_friendships }
    it do
      expect(S3::MutualFriendship).to receive(:where).with(uid: uid)
      expect(MutualFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#one_sided_friendships' do
    subject { twitter_user.one_sided_friendships }
    it do
      expect(S3::OneSidedFriendship).to receive(:where).with(uid: uid)
      expect(OneSidedFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#one_sided_followerships' do
    subject { twitter_user.one_sided_followerships }
    it do
      expect(S3::OneSidedFollowership).to receive(:where).with(uid: uid)
      expect(OneSidedFollowership).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#inactive_friendships' do
    subject { twitter_user.inactive_friendships }
    it do
      expect(S3::InactiveFriendship).to receive(:where).with(uid: uid)
      expect(InactiveFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#inactive_followerships' do
    subject { twitter_user.inactive_followerships }
    it do
      expect(S3::InactiveFollowership).to receive(:where).with(uid: uid)
      expect(InactiveFollowership).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#inactive_mutual_friendships' do
    subject { twitter_user.inactive_mutual_friendships }
    it do
      expect(S3::InactiveMutualFriendship).to receive(:where).with(uid: uid)
      expect(InactiveMutualFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#mutual_unfriendships' do
    subject { twitter_user.mutual_unfriendships }
    it do
      expect(S3::MutualUnfriendship).to receive(:where).with(uid: uid)
      expect(BlockFriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#unfriendships' do
    subject { twitter_user.unfriendships }
    it do
      expect(S3::Unfriendship).to receive(:where).with(uid: uid)
      expect(Unfriendship).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#unfollowerships' do
    subject { twitter_user.unfollowerships }
    it do
      expect(S3::Unfollowership).to receive(:where).with(uid: uid)
      expect(Unfollowership).to receive_message_chain(:where, :order).with(from_uid: uid).with(sequence: :asc)
      subject
    end
  end

  describe '#mutual_friends' do
    subject { twitter_user.mutual_friends }
    before { allow(twitter_user).to receive(:mutual_friend_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1], inactive: nil)
      subject
    end
  end

  describe '#one_sided_friends' do
    subject { twitter_user.one_sided_friends }
    before { allow(twitter_user).to receive(:one_sided_friend_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#one_sided_followers' do
    subject { twitter_user.one_sided_followers }
    before { allow(twitter_user).to receive(:one_sided_follower_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#inactive_friends' do
    subject { twitter_user.inactive_friends }
    before { allow(twitter_user).to receive(:inactive_friend_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#inactive_followers' do
    subject { twitter_user.inactive_followers }
    before { allow(twitter_user).to receive(:inactive_follower_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#inactive_mutual_friends' do
    subject { twitter_user.inactive_mutual_friends }
    before { allow(twitter_user).to receive(:inactive_mutual_friend_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#friends' do
    subject { twitter_user.friends }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: twitter_user.friend_uids, inactive: nil)
      subject
    end
  end

  describe '#followers' do
    subject { twitter_user.followers }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: twitter_user.follower_uids, inactive: nil)
      subject
    end
  end

  describe '#mutual_unfriends' do
    subject { twitter_user.mutual_unfriends }
    before { allow(twitter_user).to receive(:mutual_unfriend_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#unfriends' do
    subject { twitter_user.unfriends }
    before { allow(twitter_user).to receive(:unfriend_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#unfollowers' do
    subject { twitter_user.unfollowers }
    before { allow(twitter_user).to receive(:unfollower_uids).and_return([1]) }
    it do
      expect(TwitterDB::User).to receive(:where_and_order_by_field).with(uids: [1])
      subject
    end
  end

  describe '#mutual_friend_uids' do
    subject { twitter_user.mutual_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:mutual_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#one_sided_friend_uids' do
    subject { twitter_user.one_sided_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:one_sided_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#one_sided_follower_uids' do
    subject { twitter_user.one_sided_follower_uids }
    it do
      expect(twitter_user).to receive_message_chain(:one_sided_followerships, :pluck).with(:follower_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#inactive_mutual_friend_uids' do
    subject { twitter_user.inactive_mutual_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:inactive_mutual_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#inactive_friend_uids' do
    subject { twitter_user.inactive_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:inactive_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#inactive_follower_uids' do
    subject { twitter_user.inactive_follower_uids }
    it do
      expect(twitter_user).to receive_message_chain(:inactive_followerships, :pluck).with(:follower_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#mutual_unfriend_uids' do
    subject { twitter_user.mutual_unfriend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:mutual_unfriendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#unfriend_uids' do
    subject { twitter_user.unfriend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:unfriendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#unfollower_uids' do
    subject { twitter_user.unfollower_uids }
    it do
      expect(twitter_user).to receive_message_chain(:unfollowerships, :pluck).with(:follower_uid).and_return('result')
      is_expected.to eq('result')
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
end
