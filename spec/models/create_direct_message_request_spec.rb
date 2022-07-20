require 'rails_helper'

RSpec.describe CreateDirectMessageRequest, type: :model do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }
  let(:event) { 'event' }
  let(:instance) { create(:create_direct_message_request, sender_id: sender.uid, recipient_id: recipient.uid, properties: {event: event}) }

  describe '#perform' do
    let(:api_client) { double('api_client') }
    let(:recipient_api_client) { double('recipient_api_client') }
    let(:client) { double('twitter_client') }
    subject { instance.perform }

    before do
      allow(instance).to receive(:sender).and_return(sender)
      allow(instance).to receive(:client).and_return(client)
      allow(instance).to receive(:api_client).and_return(api_client)

      allow(instance).to receive(:recipient).and_return(recipient)
      allow(recipient).to receive(:api_client).and_return(recipient_api_client)
      allow(recipient_api_client).to receive(:verify_credentials).and_return({})
    end

    context 'egotter can send a dm to the user' do
      before { allow(PeriodicReport).to receive(:messages_not_allotted?).with(recipient).and_return(false) }
      it do
        expect(api_client).not_to receive(:create_direct_message)
        expect(client).to receive(:create_direct_message_event).with(event: event)
        subject
      end
    end

    context 'egotter can NOT send a dm to the user' do
      before { allow(PeriodicReport).to receive(:messages_not_allotted?).with(recipient).and_return(true) }
      it do
        expect(api_client).to receive(:create_direct_message).with(User::EGOTTER_UID, instance_of(String))
        expect(client).to receive(:create_direct_message_event).with(event: event)
        subject
      end
    end

    # context 'ApiClient::RetryExhausted is raised' do
    #   let(:error) { ApiClient::RetryExhausted }
    #   before { allow(recipient_api_client).to receive(:verify_credentials).and_raise(error) }
    #   it do
    #     expect(client).not_to receive(:create_direct_message_event)
    #     expect(instance).to receive(:handle_retry_exhausted)
    #     expect { subject }.to raise_error(error)
    #   end
    # end
  end

  describe '.rate_limited?' do
    subject { described_class.rate_limited? }
    it { is_expected.to be_falsey }

    context 'Many reports are sent' do
      before { 500.times { create(:create_direct_message_request, sent_at: Time.zone.now) } }
      it { is_expected.to be_truthy }
    end
  end
end
