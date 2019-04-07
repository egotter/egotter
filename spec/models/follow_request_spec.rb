require 'rails_helper'

RSpec.describe FollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.new(user: user, uid: 1) }

  describe '#perform!' do
    let(:client) { ApiClient.instance.twitter }
    subject { request.perform! }
    let(:from_uid) { user.uid }
    let(:to_uid) { request.uid }

    before do
      allow(request).to receive(:client).with(no_args).and_return(client)
      allow(request).to receive(:unauthorized?).with(no_args).and_return(false)
    end

    it 'calls client#follow!' do
      allow(client).to receive(:user?).with(to_uid).and_return(true)
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
      allow(request).to receive(:friendship_outgoing?).with(no_args).and_return(false)
      expect(client).to receive(:follow!).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      before { request.uid = user.uid }
      it do
        expect { subject }.to raise_error(FollowRequest::CanNotFollowYourself)
      end
    end

    context 'User not found.' do
      before { allow(client).to receive(:user?).with(to_uid).and_return(false) }
      it do
        expect { subject }.to raise_error(FollowRequest::NotFound)
      end
    end

    context "You've already followed the user." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true)
      end
      it do
        expect { subject }.to raise_error(FollowRequest::AlreadyFollowing)
      end
    end

    context "You've already requested to follow." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
        allow(request).to receive(:friendship_outgoing?).with(no_args).and_return(true)
      end
      it do
        expect { subject }.to raise_error(FollowRequest::AlreadyRequestedToFollow)
      end
    end
  end
end
