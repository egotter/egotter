require 'rails_helper'

RSpec.describe CreatePeriodicReportStopRequestedMessageWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    subject { worker.perform(user.id) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :send_report).with(any_args)
      subject
    end
  end
end
