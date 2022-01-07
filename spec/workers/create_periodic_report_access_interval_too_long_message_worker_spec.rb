require 'rails_helper'

RSpec.describe CreatePeriodicReportAccessIntervalTooLongMessageWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    subject { worker.perform(user.id) }
    it do
      expect(PeriodicReport).to receive_message_chain(:access_interval_too_long_message, :message).with(user.id).with(no_args).and_return('message')
      expect(User).to receive_message_chain(:egotter, :api_client, :send_report).with(any_args)
      subject
    end
  end
end
