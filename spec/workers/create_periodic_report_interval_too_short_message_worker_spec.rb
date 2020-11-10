require 'rails_helper'

RSpec.describe CreatePeriodicReportIntervalTooShortMessageWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    subject { worker.perform(user.id) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(anything)
      subject
    end
  end
end
