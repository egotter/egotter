require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Dirty do
  subject(:twitter_user) { create(:twitter_user) }

  describe '#diff' do
    context 'with same record' do
      subject(:copy) do
        build(:twitter_user, uid: twitter_user.uid, screen_name: twitter_user.screen_name)
      end

      before do
        allow(copy).to receive(:friends_count).and_return(twitter_user.friends_count)
        allow(copy).to receive(:friend_uids).and_return(twitter_user.friend_uids)
        allow(copy).to receive(:followers_count).and_return(twitter_user.followers_count)
        allow(copy).to receive(:follower_uids).and_return(twitter_user.follower_uids)
      end

      it 'returns empty hash' do
        expect(twitter_user.diff(copy).keys).to be_empty
      end
    end

    context 'with different record' do
      subject(:copy) do
        build(:twitter_user, uid: twitter_user.uid, screen_name: twitter_user.screen_name)
      end

      before do
        allow(copy).to receive(:friends_count).and_return(1)
        allow(copy).to receive(:friend_uids).and_return([twitter_user.friend_uids[0]])
        allow(copy).to receive(:followers_count).and_return(twitter_user.followers_count)
        allow(copy).to receive(:follower_uids).and_return(twitter_user.follower_uids)
      end

      it 'returns hash with keys' do
        expect(twitter_user.diff(copy).keys).to match_array(%i(friends_count friend_uids))
      end
    end
  end
end
