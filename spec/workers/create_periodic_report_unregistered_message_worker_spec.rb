require 'rails_helper'

RSpec.describe CreatePeriodicReportUnregisteredMessageWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(1) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(anything)
      subject
    end
  end
end
