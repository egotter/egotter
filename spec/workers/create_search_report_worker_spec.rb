require 'rails_helper'

RSpec.describe CreateSearchReportWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
    allow(user).to receive(:unauthorized_or_expire_token?).and_return(false)
  end

  describe '#perform' do
    let(:options) { {} }
    subject { worker.perform(user.id, options) }
    it do
      expect(SearchReport).to receive_message_chain(:you_are_searched, :deliver!).
          with(user.id, anything).with(no_args)
      subject
    end

    context 'sending DM is rate-limited' do
      before { allow(PeriodicReport).to receive(:send_report_limited?).with(user.uid).and_return(true) }
      it do
        expect(worker).to receive(:retry_current_report).with(user.id, options)
        expect(SearchReport).not_to receive(:you_are_searched)
        subject
      end
    end
  end
end
