require 'rails_helper'

RSpec.describe CreateTwitterUserNewFriendsWorker do
  let(:twitter_user) { create(:twitter_user, user_id: 1) }
  let(:new_friend_uids) { [1, 2, 3] }
  let(:new_follower_uids) { [3, 4, 5, 6] }
  let(:worker) { described_class.new }

  before do
    allow(twitter_user).to receive(:calc_new_friend_uids).and_return(new_friend_uids)
    allow(twitter_user).to receive(:calc_new_follower_uids).and_return(new_follower_uids)
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(twitter_user).to receive(:update).with(new_friends_size: new_friend_uids.size)
      expect(twitter_user).to receive(:update).with(new_followers_size: new_follower_uids.size)
      expect(NewFriendsCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 3)
      expect(NewFollowersCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 4)
      expect(CreateTwitterDBUsersForMissingUidsWorker).to receive(:push_bulk).with([1, 2, 3, 3, 4, 5, 6], 1, enqueued_by: described_class)
      subject
    end
  end
end
