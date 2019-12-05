require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Dirty do
  let(:twitter_user) { create(:twitter_user, friends_count: 5, followers_count: 5) }

  describe '#diff' do
    subject { twitter_user.diff(copied) }

    context 'Same record is passed' do
      let(:copied) do
        build(:twitter_user, uid: twitter_user.uid, screen_name: twitter_user.screen_name)
      end

      before do
        allow(copied).to receive(:friends_count).and_return(twitter_user.friends_count)
        allow(copied).to receive(:friend_uids).and_return(twitter_user.friend_uids)
        allow(copied).to receive(:followers_count).and_return(twitter_user.followers_count)
        allow(copied).to receive(:follower_uids).and_return(twitter_user.follower_uids)
      end

      it { is_expected.to be_empty }
    end

    context 'Different record is passed' do
      let(:copied) do
        build(:twitter_user, uid: twitter_user.uid, screen_name: twitter_user.screen_name)
      end

      before do
        allow(copied).to receive(:friends_count).and_return(1)
        allow(copied).to receive(:friend_uids).and_return([2, 3, 4])
        allow(copied).to receive(:followers_count).and_return(5)
        allow(copied).to receive(:follower_uids).and_return([6, 7])
      end

      it do
        is_expected.to match(friends_count: [twitter_user.friends_count, 1],
                             friend_uids: [twitter_user.friend_uids.sort, [2, 3, 4]],
                             follower_uids: [twitter_user.follower_uids.sort, [6, 7]])
      end
    end
  end
end
