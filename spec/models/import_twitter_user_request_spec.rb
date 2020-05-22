require 'rails_helper'

RSpec.describe ImportTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, with_relations: false) }
  let(:request) { described_class.create!(user_id: user.id, twitter_user: twitter_user) }

  describe '#perform!' do
    subject { request.perform! }

    it do
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

  describe '#import_unfollowership' do

  end
end
