require 'rails_helper'

RSpec.describe AssembleTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id, with_relations: false) }
  let(:request) { described_class.create!(twitter_user: twitter_user) }

  before do
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
  end

  describe '#perform!' do
    subject { request.perform! }

    it do
      expect(UpdateUsageStatWorker).to receive(:perform_async).with(twitter_user.uid, user_id: twitter_user.user_id, location: described_class)
      expect(UpdateAudienceInsightWorker).to receive(:perform_async).with(twitter_user.uid, anything)
      expect(CreateFriendInsightWorker).to receive(:perform_async).with(twitter_user.uid, anything)
      expect(CreateFollowerInsightWorker).to receive(:perform_async).with(twitter_user.uid, anything)
      expect(CreateTopFollowerWorker).to receive(:perform_async).with(twitter_user.id)

      expect(request).to receive(:perform_direct)
      subject
    end
  end

  describe 'perform_direct' do
    subject { request.send(:perform_direct) }

    it do
      expect(CreateTwitterUserCloseFriendsWorker).to receive(:perform_async).with(twitter_user.id)
      expect(CreateTwitterUserInactiveFriendsWorker).to receive(:perform_async).with(twitter_user.id)
      expect(CreateTwitterUserUnfriendsWorker).to receive(:perform_async).with(twitter_user.id)
      subject
    end
  end
end
