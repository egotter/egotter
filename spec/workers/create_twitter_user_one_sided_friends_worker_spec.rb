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
      expect(twitter_user).to receive(:calc_and_import).with(S3::OneSidedFriendship).and_return([1, 2])
      expect(twitter_user).to receive(:calc_and_import).with(S3::OneSidedFollowership).and_return([2, 3, 4])
      expect(twitter_user).to receive(:calc_and_import).with(S3::MutualFriendship).and_return([2])

      expect(OneSidedFriendsCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 2)
      expect(OneSidedFollowersCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 3)
      expect(MutualFriendsCountPoint).to receive(:create).with(uid: twitter_user.uid, value: 1)
      subject
    end
  end
end
