require 'rails_helper'

RSpec.describe WebhookController, type: :controller do

  describe 'POST #twitter' do
    let(:params) { {direct_message_events: ['event1', 'event2']} }
    subject { post :twitter, params: params }

    before do
      allow(controller).to receive(:verify_webhook_request)
      allow(controller).to receive(:direct_message_event_for_egotter?).and_return(true)
    end

    it do
      params[:direct_message_events].each do |event|
        expect(ProcessWebhookEventWorker).to receive(:perform_async).with(event)
      end
      is_expected.to have_http_status(:ok)
    end
  end

  describe '#direct_message_event_for_egotter?' do
    subject { controller.send(:direct_message_event_for_egotter?) }
    before do
      allow(controller.params).to receive(:[]).with(:for_user_id).and_return(User::EGOTTER_UID.to_s)
      allow(controller.params).to receive(:[]).with(:direct_message_events).and_return('events')
    end
    it { is_expected.to be_truthy }
  end

  describe '#track_twitter_webhook' do
    let(:events) do
      [{id: 123, type: 'ttt', message_create: {target: 't', sender_id: 's'}, created_timestamp: Time.zone.now.to_i}]
    end
    subject { controller.send(:track_twitter_webhook) }
    before do
      allow(controller.params).to receive(:[]).with(:direct_message_events).and_return(events)
      allow(controller.params).to receive(:[]).with(:for_user_id).and_return(111)
    end
    it { is_expected.to be_truthy }
  end
end
