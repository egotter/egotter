require 'rails_helper'

RSpec.describe CreateTwitterUserUnfriendsWorker do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id) }
  let(:worker) { described_class.new }

  before do
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
    allow(User).to receive(:find_by).with(id: twitter_user.user_id).and_return(user)
  end

  describe '#perform' do
    let(:uids1) { [1, 2] }
    let(:uids2) { [2, 3] }
    let(:uids3) { [3, 4] }
    subject { worker.perform(twitter_user.id) }
    it do
      expect(twitter_user).to receive(:calc_and_import).with(S3::Unfriendship).and_return(uids1)
      expect(twitter_user).to receive(:calc_and_import).with(S3::Unfollowership).and_return(uids2)
      expect(twitter_user).to receive(:calc_and_import).with(S3::MutualUnfriendship).and_return(uids3)
      expect(CreateTwitterDBUserWorker).to receive(:perform_async).with([1, 2, 2, 3, 3, 4], user_id: user.id, enqueued_by: described_class)
      expect(DeleteUnfriendshipsWorker).to receive(:perform_async).with(twitter_user.uid)
      subject
    end
  end
end
