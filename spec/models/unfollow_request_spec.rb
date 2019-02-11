require 'rails_helper'

RSpec.describe UnfollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.new(user: user, uid: 1) }

  # describe '#can_perform?' do
  #   subject { request.can_perform? }
  #   it { is_expected.to be_truthy }
  #
  #   it 'calls .global_can_perform?' do
  #     expect(described_class).to receive(:global_can_perform?)
  #     subject
  #   end
  #
  #   it 'calls user.can_create_unfollow?' do
  #     allow(described_class).to receive(:global_can_perform?).and_return(true)
  #     expect(user).to receive(:can_create_unfollow?)
  #     subject
  #   end
  # end

  describe '#perform!' do
    let(:client) { ApiClient.instance.twitter }
    subject { request.perform!(client) }
    let(:from_uid) { user.uid }
    let(:to_uid) { request.uid }

    it 'calls client#unfollow' do
      allow(client).to receive(:user?).with(to_uid).and_return(true)
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true)
      expect(client).to receive(:unfollow).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      before { request.uid = user.uid }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::CanNotUnfollowYourself)
      end
    end

    context 'User not found.' do
      before { allow(client).to receive(:user?).with(to_uid).and_return(false) }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::NotFound)
      end
    end

    context "You haven't followed the user." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
      end
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::HaveNotFollowed)
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
