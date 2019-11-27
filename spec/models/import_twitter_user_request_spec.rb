require 'rails_helper'

RSpec.describe ImportTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user) }

  describe '#perform!' do
    let(:request) { ImportTwitterUserRequest.create!(user_id: user.id, twitter_user: twitter_user) }
    subject { request.perform! }

    it do
      expect(request).to receive(:import_favorite_friendship).with(no_args)
      expect(request).to receive(:import_close_friendship).with(no_args)
      expect(request).to receive(:import_unfollowership).with(no_args)

      [
          Unfriendship,
          OneSidedFriendship,
          OneSidedFollowership,
          MutualFriendship,
          BlockFriendship,
          InactiveFriendship,
          InactiveFollowership,
          InactiveMutualFriendship,
      ].each do |klass|
        expect(klass).to receive(:import_by!).with(twitter_user: twitter_user)
      end

      subject
    end
  end

  describe '#import_unfollowership' do

  end
end
