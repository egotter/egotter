require 'rails_helper'

RSpec.describe CreateTwitterUserOneSidedFriendsWorker do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id) }
  let(:worker) { described_class.new }

  before do
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
    allow(User).to receive(:find_by).with(id: twitter_user.user_id).and_return(user)
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(worker).to receive(:import_uids).with(S3::OneSidedFriendship, twitter_user).and_return([1, 2])
      expect(worker).to receive(:import_uids).with(S3::OneSidedFollowership, twitter_user).and_return([2, 3, 4])
      expect(worker).to receive(:import_uids).with(S3::MutualFriendship, twitter_user).and_return([2])
      expect(CreateOneSidedFriendsCountPointWorker).to receive(:perform_async).with(twitter_user.uid, 2)
      expect(CreateOneSidedFollowersCountPointWorker).to receive(:perform_async).with(twitter_user.uid, 3)
      expect(CreateMutualFriendsCountPointWorker).to receive(:perform_async).with(twitter_user.uid, 1)
      expect(DeleteOneSidedFriendshipsWorker).to receive(:perform_async).with(twitter_user.uid)
      subject
    end
  end

  describe '#import_uids' do
    let(:klass) { S3::OneSidedFriendship }
    let(:uids) { [1] }
    subject { worker.send(:import_uids, klass, twitter_user) }
    before { allow(twitter_user).to receive(:calc_uids_for).with(klass).and_return(uids) }
    it do
      expect(klass).to receive(:import_from!).with(twitter_user.uid, uids)
      expect(twitter_user).to receive(:update_counter_cache_for).with(klass, uids.size)
      subject
    end
  end
end
