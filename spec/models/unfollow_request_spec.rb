require 'rails_helper'

RSpec.describe UnfollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.new(user: user, uid: 1) }

  describe '#reqdy?' do
    subject { request.ready? }
    it { is_expected.to be_truthy }

    it 'calls Concerns::User::FollowAndUnfollow::Util.global_can_create_unfollow?' do
      expect(Concerns::User::FollowAndUnfollow::Util).to receive(:global_can_create_unfollow?)
      subject
    end

    it 'calls user.can_create_unfollow?' do
      allow(Concerns::User::FollowAndUnfollow::Util).to receive(:global_can_create_unfollow?).and_return(true)
      expect(user).to receive(:can_create_unfollow?)
      subject
    end
  end
end
