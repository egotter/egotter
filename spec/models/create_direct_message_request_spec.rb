require 'rails_helper'

RSpec.describe CreateDirectMessageRequest, type: :model do
  let(:instance) { create(:create_direct_message_request, sender_id: 1, recipient_id: 2) }

  describe '#perform' do
    let(:client) { double('client') }
    subject { instance.perform }
    before do
      allow(instance).to receive(:api_client).and_return(client)
      instance.properties = {message: 'message'}
    end
    it do
      expect(client).to receive(:create_direct_message).with(2, 'message')
      is_expected.to be_truthy
    end
  end
end
