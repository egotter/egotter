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

  describe '#perform!' do
    let(:client) { ApiClient.instance.twitter }
    subject { request.perform!(client) }
    let(:from_uid) { user.uid }
    let(:to_uid) { request.uid }

    it 'calls client#follow!' do
      allow(client).to receive(:user?).with(to_uid).and_return(true)
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
      allow(request).to receive(:friendship_outgoing?).with(client, to_uid).and_return(false)
      expect(client).to receive(:follow!).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      before { request.uid = user.uid }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::CanNotFollowYourself)
      end
    end

    context 'User not found.' do
      before { allow(client).to receive(:user?).with(to_uid).and_return(false) }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::NotFound)
      end
    end

    context "You've already followed the user." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true)
      end
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::HaveAlreadyFollowed)
      end
    end

    context "You've already requested to follow." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
        allow(request).to receive(:friendship_outgoing?).with(client, to_uid).and_return(true)
      end
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::HaveAlreadyRequestedToFollow)
      end
    end
  end

  describe '#perform' do
    let(:client) { ApiClient.instance.twitter }
    subject { request.perform(client) }

    it 'calls #perform!' do
      expect(request).to receive(:perform!).with(client)
      subject
    end
  end
end
