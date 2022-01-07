require 'rails_helper'

RSpec.describe CreatePeriodicReportReceivedMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.uid) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :send_report).with(any_args)
      subject
    end
  end

  describe '#short_message' do
    subject { worker.send(:short_message, user.uid) }
    it { is_expected.to be_truthy }
  end
end
