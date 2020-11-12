require 'rails_helper'

RSpec.describe CreateBlockReportWorker do
  let(:user) { create(:user, with_settings: true) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    subject { worker.perform(user.id) }

    before do
      create(:blocking_relationship, from_uid: 1, to_uid: user.uid)
    end

    context '#has_valid_subscription? returns true' do
      before { allow(user).to receive(:has_valid_subscription?).and_return(true) }
      it do
        expect(BlockReport).to receive(:you_are_blocked).with(user.id)
        subject
      end
    end

    context '#has_valid_subscription? returns false' do
      before { allow(user).to receive(:has_valid_subscription?).and_return(false) }
      it do
        expect(CreateBlockReportNotFollowingMessageWorker).to receive(:perform_async).with(user.id)
        subject
      end
    end
  end
end
