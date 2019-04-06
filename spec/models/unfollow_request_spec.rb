require 'rails_helper'

RSpec.describe UnfollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.new(user: user, uid: 1) }

  describe '#perform!' do
    let(:client) { ApiClient.instance.twitter }
    subject { request.perform! }
    let(:from_uid) { user.uid }
    let(:to_uid) { request.uid }

    before { allow(request).to receive(:client).with(no_args).and_return(client) }

    it 'calls client#unfollow' do
      allow(client).to receive(:user?).with(to_uid).and_return(true)
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true)
      expect(client).to receive(:unfollow).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      before { request.uid = user.uid }
      it do
        expect { subject }.to raise_error(UnfollowRequest::CanNotUnfollowYourself)
      end
    end

    context 'User not found.' do
      before { allow(client).to receive(:user?).with(to_uid).and_return(false) }
      it do
        expect { subject }.to raise_error(UnfollowRequest::NotFound)
      end
    end

    context "You haven't followed the user." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
      end
      it do
        expect { subject }.to raise_error(UnfollowRequest::NotFollowing)
      end
    end
  end
end
