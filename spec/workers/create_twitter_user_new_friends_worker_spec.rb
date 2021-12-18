require 'rails_helper'

RSpec.describe CreateTwitterUserNewFriendsWorker do
  let(:twitter_user) { create(:twitter_user, user_id: 1) }
  let(:uids) { [1, 2, 3] }
  let(:worker) { described_class.new }

  before do
    allow(twitter_user).to receive(:calc_new_friend_uids).and_return(uids)
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(twitter_user).to receive(:update).with(new_friends_size: uids.size)
      expect(worker).to receive(:update_twitter_db_users).with(uids, twitter_user.user_id)
      expect(CreateNewFriendsCountPointWorker).to receive(:perform_async).with(twitter_user.uid, uids.size)
      subject
    end
  end
end
