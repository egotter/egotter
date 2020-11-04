require 'rails_helper'

RSpec.describe CreateBlockReportWorker do
  let(:user) { create(:user, with_settings: true) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      create(:blocking_relationship, from_uid: 1, to_uid: user.uid)
    end

    it do
      expect(BlockReport).to receive(:you_are_blocked).with(user.id)
      subject
    end
  end

  describe '#send_report?' do
    subject { worker.send(:send_report?, user) }
    it { is_expected.to be_truthy }

    context 'stop is requested' do
      before { StopBlockReportRequest.create(user_id: user.id) }
      it { is_expected.to be_falsey }
    end
  end
end
