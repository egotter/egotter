require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  describe '#save' do
    let(:twitter_user) { build(:twitter_user) }
    let(:friend_uids) { twitter_user.friendships.map(&:friend_uid) }
    let(:follower_uids) { twitter_user.followerships.map(&:follower_uid) }

    before do
      friend_uids
      follower_uids
    end

    it 'saves friendships' do
      expect { twitter_user.save! }.to change { Friendship.all.size }.by(friend_uids.size)
      expect(twitter_user.friendships.pluck(:friend_uid)).to match_array(friend_uids)
      expect(twitter_user.friends_size).to eq(friend_uids.size)
    end

    it 'saves followerships' do
      expect { twitter_user.save! }.to change { Followership.all.size }.by(follower_uids.size)
      expect(twitter_user.followerships.pluck(:follower_uid)).to match_array(follower_uids)
      expect(twitter_user.followers_size).to eq(follower_uids.size)
    end

    it 'saves statuses' do
      size = twitter_user.statuses.size
      expect { twitter_user.save }.to change { TwitterDB::Status.all.size }.by(size)
    end

    it 'saves mentions' do
      size = twitter_user.mentions.size
      expect { twitter_user.save }.to change { TwitterDB::Mention.all.size }.by(size)
    end

    it 'saves favorites' do
      size = twitter_user.favorites.size
      expect { twitter_user.save }.to change { TwitterDB::Favorite.all.size }.by(size)
    end
  end
end
