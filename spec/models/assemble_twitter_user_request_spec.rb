require 'rails_helper'

RSpec.describe AssembleTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id, with_relations: false) }
  let(:request) { described_class.create!(twitter_user: twitter_user) }

  describe '#perform!' do
    subject { request.perform! }

    before do
      allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    end

    it do
      expect(UpdateUsageStatWorker).to receive(:perform_async).
          with(twitter_user.uid, user_id: twitter_user.user_id, location: described_class)
      expect(UpdateAudienceInsightWorker).to receive(:perform_async).
          with(twitter_user.uid, location: described_class)
      expect(CreateFriendInsightWorker).to receive(:perform_async).
          with(twitter_user.uid, location: described_class)
      expect(CreateFollowerInsightWorker).to receive(:perform_async).
          with(twitter_user.uid, location: described_class)
      expect(CreateTopFollowerWorker).to receive(:perform_async).with(twitter_user.id)

      [
          S3::CloseFriendship,
          S3::FavoriteFriendship,
      ].each do |klass|
        expect(twitter_user).to receive(:calc_uids_for).with(klass, login_user: user).and_return("result of #{klass}")
        expect(klass).to receive(:import_from!).with(twitter_user.uid, "result of #{klass}")
      end

      [
          S3::OneSidedFriendship,
          S3::OneSidedFollowership,
          S3::MutualFriendship,
          S3::InactiveFriendship,
          S3::InactiveFollowership,
          S3::InactiveMutualFriendship,
          S3::Unfriendship,
          S3::Unfollowership,
          S3::MutualUnfriendship,
      ].each.with_index do |klass, i|
        uids = Array.new(3).map { i }
        expect(twitter_user).to receive(:calc_uids_for).with(klass).and_return(uids)
        expect(klass).to receive(:import_from!).with(twitter_user.uid, uids)
        expect(twitter_user).to receive(:update_counter_cache_for).with(klass, uids.size)
      end

      expect(DeleteDisusedRecordsWorker).to receive(:perform_async).with(twitter_user.uid)

      subject
    end
  end
end
