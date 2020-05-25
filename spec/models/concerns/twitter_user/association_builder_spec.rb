require 'rails_helper'

RSpec.describe Concerns::TwitterUser::AssociationBuilder do
  let(:twitter_user) { TwitterUser.new }

  describe '#attach_friend_uids' do
    subject { twitter_user.attach_friend_uids(uids) }

    context 'uids is an array' do
      let(:uids) { [1, 2, 3] }
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_friend_uids)).to eq(uids)
        expect(twitter_user.friends_size).to eq(uids.size)
      end
    end

    context 'uids is nil' do
      let(:uids) { nil }
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_friend_uids)).to be_empty
        expect(twitter_user.friends_size).to eq(0)
      end
    end
  end

  describe '#attach_follower_uids' do
    subject { twitter_user.attach_follower_uids(uids) }

    context 'uids is an array' do
      let(:uids) { [1, 2, 3] }
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_follower_uids)).to eq(uids)
        expect(twitter_user.followers_size).to eq(uids.size)
      end
    end

    context 'uids is nil' do
      let(:uids) { nil }
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_follower_uids)).to be_empty
        expect(twitter_user.followers_size).to eq(0)
      end
    end
  end

  describe '#attach_user_timeline' do
    subject { twitter_user.attach_user_timeline(tweets) }

    context 'tweets is an array' do
      let(:tweets) { ['tweet0', 'tweet1'] }
      let(:result) { ['result0', 'result1'] }
      before do
        tweets.each.with_index do |tweet, i|
          allow(TwitterDB::Status).to receive(:build_by).with(twitter_user: twitter_user, status: tweet).and_return(result[i])
        end
      end
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_statuses)).to eq(result)
      end
    end

    context 'tweets is nil' do
      let(:tweets) { nil }
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_statuses)).to be_empty
      end
    end
  end

  describe '#attach_mentions_timeline' do
    subject { twitter_user.attach_mentions_timeline(tweets, search_result) }

    context 'tweets is an array' do
      let(:tweets) { ['tweet0', 'tweet1'] }
      let(:search_result) { 'anything' }
      let(:result) { ['result0', 'result1'] }
      before do
        tweets.each.with_index do |tweet, i|
          allow(TwitterDB::Mention).to receive(:build_by).with(twitter_user: twitter_user, status: tweet).and_return(result[i])
        end
      end
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_mentions)).to eq(result)
      end
    end

    context 'tweets is nil' do
      let(:tweets) { nil }

      context 'search_result is an array' do
        let(:search_result) { ['search0', 'search1'] }
        let(:result) { ['result0', 'result1'] }
        before do
          allow(twitter_user).to receive(:reject_self_tweet_and_retweet).with(search_result).and_return(search_result)

          search_result.each.with_index do |tweet, i|
            allow(TwitterDB::Mention).to receive(:build_by).with(twitter_user: twitter_user, status: tweet).and_return(result[i])
          end
        end
        it do
          subject
          expect(twitter_user.instance_variable_get(:@reserved_mentions)).to eq(result)
        end
      end

      context 'search_result is nil' do
        let(:search_result) { nil }
        it do
          subject
          expect(twitter_user.instance_variable_get(:@reserved_mentions)).to be_empty
        end
      end
    end
  end

  describe '#attach_favorite_tweets' do
    subject { twitter_user.attach_favorite_tweets(tweets) }

    context 'tweets is an array' do
      let(:tweets) { ['tweet0', 'tweet1'] }
      let(:result) { ['result0', 'result1'] }
      before do
        tweets.each.with_index do |tweet, i|
          allow(TwitterDB::Favorite).to receive(:build_by).with(twitter_user: twitter_user, status: tweet).and_return(result[i])
        end
      end
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_favorites)).to eq(result)
      end
    end

    context 'tweets is nil' do
      let(:tweets) { nil }
      it do
        subject
        expect(twitter_user.instance_variable_get(:@reserved_favorites)).to be_empty
      end
    end
  end

end