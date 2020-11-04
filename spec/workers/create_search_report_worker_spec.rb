require 'rails_helper'

RSpec.describe CreateSearchReportWorker do
  let(:user) { create(:user, with_settings: true) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.id) }
    it do
      expect(SearchReport).to receive_message_chain(:you_are_searched, :deliver!).
          with(user.id, anything).with(no_args)
      subject
    end
  end

  describe '#send_report?' do
    subject { worker.send(:send_report?, user) }
    it { is_expected.to be_truthy }

    context 'stop is requested' do
      before { StopSearchReportRequest.create(user_id: user.id) }
      it { is_expected.to be_falsey }
    end
  end
end
