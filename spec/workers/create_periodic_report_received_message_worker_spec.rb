require 'rails_helper'

RSpec.describe CreatePeriodicReportReceivedMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.uid) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(anything)
      subject
    end
  end
end
