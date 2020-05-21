require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Dirty do
  let(:friend_uids) { [1, 2, 3, 4, 5].shuffle }
  let(:friends_count) { friend_uids.size }
  let(:follower_uids) { [1, 2, 3, 4, 5, 6, 7, 8, 9].shuffle }
  let(:followers_count) { follower_uids.size }
  let(:twitter_user) { build(:twitter_user) }

  shared_context 'copy record' do
    let(:copied) { double('twitter_user') }
    before do
      allow(copied).to receive(:friends_count).and_return(new_friends_count)
      allow(copied).to receive(:friend_uids).and_return(new_friend_uids)
      allow(copied).to receive(:followers_count).and_return(new_followers_count)
      allow(copied).to receive(:follower_uids).and_return(new_follower_uids)
    end
  end

  describe '#diff' do
    subject { twitter_user.diff(copied) }

    before do
      allow(twitter_user).to receive(:friends_count).and_return(friends_count)
      allow(twitter_user).to receive(:friend_uids).and_return(friend_uids)
      allow(twitter_user).to receive(:followers_count).and_return(followers_count)
      allow(twitter_user).to receive(:follower_uids).and_return(follower_uids)
    end

    context 'all values are the same' do
      let(:new_friend_uids) { friend_uids }
      let(:new_friends_count) { friend_uids.size }
      let(:new_follower_uids) { follower_uids }
      let(:new_followers_count) { follower_uids.size }

      include_context 'copy record'

      it { is_expected.to be_empty }
    end

    context 'all values are different' do
      let(:new_friend_uids) { [2, 3, 4].shuffle }
      let(:new_friends_count) { new_friend_uids.size }
      let(:new_follower_uids) { [6, 7, 8].shuffle }
      let(:new_followers_count) { new_follower_uids.size }

      include_context 'copy record'

      specify 'friend_uids is sorted' do
        is_expected.to satisfy do |result|
          result[:friend_uids][0] == friend_uids.sort &&
              result[:friend_uids][1] == new_friend_uids.sort
        end
      end

      specify 'follower_uids is sorted' do
        is_expected.to satisfy do |result|
          result[:follower_uids][0] == follower_uids.sort &&
              result[:follower_uids][1] == new_follower_uids.sort
        end
      end

      specify 'result includes 4 keys' do
        is_expected.to satisfy do |result|
          result.keys.size == 4
        end
      end

      specify 'result is correct' do
        is_expected.to satisfy do |result|
          result[:friends_count] == [friends_count, new_friends_count] &&
              result[:friend_uids] == [friend_uids.sort, new_friend_uids.sort] &&
              result[:followers_count] == [followers_count, new_followers_count] &&
              result[:follower_uids] == [follower_uids.sort, new_follower_uids.sort]
        end
      end
    end

    context 'friend_uids is different' do
      let(:new_friend_uids) { [2, 3, 4].shuffle }
      let(:new_friends_count) { new_friend_uids.size }
      let(:new_follower_uids) { follower_uids }
      let(:new_followers_count) { followers_count }

      include_context 'copy record'

      specify 'friend_uids is sorted' do
        is_expected.to satisfy do |result|
          result[:friend_uids][0] == friend_uids.sort &&
              result[:friend_uids][1] == new_friend_uids.sort
        end
      end

      specify "result doesn't have :followers_count and follower_uids" do
        is_expected.to satisfy do |result|
          !result.has_key?(:followers_count) &&
              !result.has_key?(:follower_uids)
        end
      end

      specify 'result includes 2 keys' do
        is_expected.to satisfy do |result|
          result.keys.size == 2
        end
      end

      specify 'result is correct' do
        is_expected.to satisfy do |result|
          result[:friends_count] == [friends_count, new_friends_count] &&
              result[:friend_uids] == [friend_uids.sort, new_friend_uids.sort]
        end
      end
    end

  end
end
