require 'rails_helper'

RSpec.describe FollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.new(user: user, uid: 1) }

  describe '#reqdy?' do
    subject { request.ready? }
    it { is_expected.to be_truthy }

    it 'calls Concerns::User::FollowAndUnfollow::Util.global_can_create_follow?' do
      expect(Concerns::User::FollowAndUnfollow::Util).to receive(:global_can_create_follow?)
      subject
    end

    it 'calls user.can_create_follow?' do
      allow(Concerns::User::FollowAndUnfollow::Util).to receive(:global_can_create_follow?).and_return(true)
      expect(user).to receive(:can_create_follow?)
      subject
    end
  end
end
