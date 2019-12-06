require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Persistence do
  let(:twitter_user) { build(:twitter_user) }

  context 'friendships' do
    let!(:friend_uids) { twitter_user.friend_uids }

    before { twitter_user.save! }

    it { expect(twitter_user.friends_size).to eq(friend_uids.size) }

    it 'saves friendships to efs' do
      expect(Efs::TwitterUser.find_by(twitter_user.id)[:friend_uids]).to match(friend_uids)
    end

    it 'saves friendships to s3' do
      expect(S3::Friendship.find_by(twitter_user_id: twitter_user.id)[:friend_uids]).to match(friend_uids)
    end
  end

  context 'followerships' do
    let!(:follower_uids) { twitter_user.follower_uids }

    before { twitter_user.save! }

    it { expect(twitter_user.followers_size).to eq(follower_uids.size) }

    it 'saves followerships to efs' do
      expect(Efs::TwitterUser.find_by(twitter_user.id)[:follower_uids]).to match(follower_uids)
    end

    it 'saves followerships to s3' do
      expect(S3::Followership.find_by(twitter_user_id: twitter_user.id)[:follower_uids]).to match(follower_uids)
    end
  end

  context 'statuses' do
    it 'saves statuses' do
      size = twitter_user.statuses.size
      expect { twitter_user.save! }.to change { TwitterDB::Status.all.size }.by(size)
    end
  end

  context 'mentions' do
    it 'saves mentions' do
      size = twitter_user.mentions.size
      expect(size).not_to eq(0)
      expect { twitter_user.save! }.to change { TwitterDB::Mention.all.size }.by(size)
    end
  end

  context 'favorites' do
    it 'saves favorites' do
      size = twitter_user.favorites.size
      expect(size).not_to eq(0)
      expect { twitter_user.save! }.to change { TwitterDB::Favorite.all.size }.by(size)
    end
  end
end
