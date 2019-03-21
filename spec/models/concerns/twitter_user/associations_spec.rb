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

  describe '#unfriendships' do
    let(:copy1) do
      build(:twitter_user, uid: twitter_user.uid, created_at: twitter_user.created_at + 1.second)
    end
    let(:copy2) do
      build(:twitter_user, uid: copy1.uid, created_at: copy1.created_at + 1.second)
    end

    before do
      copy1.save(validate: false)
      S3::Friendship.import_from!(copy1.id, copy1.uid, copy1.screen_name, twitter_user.friend_uids)
    end

    context 'Not removed' do
      it { expect(copy1.calc_unfriend_uids.size).to eq(0) }
    end

    context 'Removed from 1 user' do
      before do
        copy2.save(validate: false)
        S3::Friendship.import_from!(copy2.id, copy2.uid, copy2.screen_name, [twitter_user.friend_uids[0]])
      end

      it { expect(copy2.calc_unfriend_uids.size).to eq(1) }
    end
  end

  describe '#unfollowerships' do
    let(:copy1) do
      build(:twitter_user, uid: twitter_user.uid, created_at: twitter_user.created_at + 1.second)
    end
    let(:copy2) do
      build(:twitter_user, uid: copy1.uid, created_at: copy1.created_at + 1.second)
    end

    before do
      copy1.save(validate: false)
      S3::Followership.import_from!(copy1.id, copy1.uid, copy1.screen_name, twitter_user.follower_uids)
    end

    context 'Not removed' do
      it { expect(copy1.calc_unfollower_uids.size).to eq(0) }
    end

    context 'Removed from 1 user' do
      before do
        copy2.save(validate: false)
        S3::Followership.import_from!(copy2.id, copy2.uid, copy2.screen_name, [twitter_user.follower_uids[0]])
      end

      it { expect(copy2.calc_unfollower_uids.size).to eq(1) }
    end
  end
end