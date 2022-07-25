require 'rails_helper'

RSpec.describe CreateTwitterUserInactiveFriendsWorker do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id) }
  let(:worker) { described_class.new }

  before do
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(twitter_user).to receive(:calc_and_import).with(S3::InactiveFriendship).and_return([1, 2])
      expect(twitter_user).to receive(:calc_and_import).with(S3::InactiveFollowership).and_return([2, 3, 4])
      expect(twitter_user).to receive(:calc_and_import).with(S3::InactiveMutualFriendship)
      expect(InactiveFriendsCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 2)
      expect(InactiveFollowersCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 3)
      expect(DeleteInactiveFriendshipsWorker).to receive(:perform_async).with(twitter_user.uid)
      subject
    end
  end
end
