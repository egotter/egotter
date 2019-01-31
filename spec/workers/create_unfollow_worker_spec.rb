require 'rails_helper'

RSpec.describe CreateUnfollowWorker do
  let(:client) { ApiClient.instance.twitter }

  describe '#unfollow' do
    subject { described_class.new.unfollow(client, from_uid, to_uid) }
    let(:from_uid) { 1 }
    let(:to_uid) { 2 }

    it 'calls client#unfollow' do
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true)
      expect(client).to receive(:unfollow).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      let(:from_uid) { 1 }
      let(:to_uid) { 1 }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::CanNotUnfollowYourself)
      end
    end

    context "You haven't followed the user." do
      before { allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false) }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::HaveNotFollowed)
      end
    end
  end
end
