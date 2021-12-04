require 'rails_helper'

RSpec.describe CreateTwitterUserNewFollowersWorker do
  let(:twitter_user) { create(:twitter_user, user_id: 1) }
  let(:uids) { [1, 2, 3] }
  let(:worker) { described_class.new }

  before do
    allow(twitter_user).to receive(:calc_new_follower_uids).and_return(uids)
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(twitter_user).to receive(:update).with(new_followers_size: uids.size)
      expect(CreateTwitterDBUserWorker).to receive(:compress_and_perform_async).with(uids, user_id: twitter_user.user_id, enqueued_by: worker.class)
      expect(CreateNewFollowersCountPointWorker).to receive(:perform_async).with(twitter_user.id)
      subject
    end
  end
end
