require 'rails_helper'

RSpec.describe CreateFollowWorker do
  let(:client) { ApiClient.instance.twitter }

  describe '#follow' do
    subject { described_class.new.follow(client, from_uid, to_uid) }
    let(:from_uid) { 1 }
    let(:to_uid) { 2 }

    it 'calls client#follow!' do
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
      expect(client).to receive(:follow!).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      let(:from_uid) { 1 }
      let(:to_uid) { 1 }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::CanNotFollowYourself)
      end
    end

    context "You've already followed the user." do
      before { allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true) }
      it do
        expect { subject }.to raise_error(Concerns::FollowAndUnfollowWorker::HaveAlreadyFollowed)
      end
    end
  end
end
