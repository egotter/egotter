require 'rails_helper'

RSpec.describe CreatePeriodicReportReceivedWebAccessMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.uid) }
    before { allow(PeriodicReport).to receive(:access_interval_too_long?).with(anything).and_return(true) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(user.uid, instance_of(String))
      subject
    end
  end
end