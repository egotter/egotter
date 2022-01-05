require 'rails_helper'

RSpec.describe CreatePeriodicReportNotFollowingMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before { user.create_credential_token!(token: 't', secret: 's') }

  describe '#perform' do
    subject { worker.perform(user.id) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(anything)
      subject
    end
  end
end
