require 'rails_helper'

RSpec.describe AssembleTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, with_relations: false) }
  let(:request) { described_class.create!(twitter_user: twitter_user) }

  describe '#perform!' do
    subject { request.perform! }

    it do
      expect(UpdateUsageStatWorker).to receive(:perform_async).
          with(twitter_user.uid, user_id: twitter_user.user_id, location: described_class)
      expect(UpdateAudienceInsightWorker).to receive(:perform_async).
          with(twitter_user.uid, location: described_class)

      expect(request).to receive(:import_favorite_friendship)
      expect(request).to receive(:import_close_friendship)
      expect(request).to receive(:import_unfollowership)

      [
          Unfriendship,
          BlockFriendship
      ].each do |klass|
        expect(klass).to receive(:import_by!).with(twitter_user: twitter_user)
      end

      [
          S3::OneSidedFriendship,
          S3::OneSidedFollowership,
          S3::MutualFriendship,
          S3::InactiveFriendship,
          S3::InactiveFollowership,
          S3::InactiveMutualFriendship
      ].each do |klass|
        expect(twitter_user).to receive(:calc_uids_for).with(klass).and_return("result of #{klass}")
        expect(klass).to receive(:import_from!).with(twitter_user.uid, "result of #{klass}")
      end

      subject
    end
  end
end
