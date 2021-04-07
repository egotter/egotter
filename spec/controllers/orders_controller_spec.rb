require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  before do
    allow(controller).to receive(:current_user_has_dm_permission?)
  end

  describe 'POST #checkout_session_completed' do
    subject { post :checkout_session_completed, params: {} }
    it do
      expect(controller).to receive(:construct_webhook_event).and_return('event')
      expect(controller).to receive(:process_webhook_event).with('event')
      is_expected.to have_http_status(:ok)
    end
  end

  describe '#construct_webhook_event' do
    let(:request) { double('request') }
    subject { controller.send(:construct_webhook_event) }
    before do
      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:body).and_return(StringIO.new('payload'))
      allow(request).to receive(:headers).and_return({'HTTP_STRIPE_SIGNATURE' => 'signature'})
    end
    it do
      expect(Stripe::Webhook).to receive(:construct_event).with('payload', 'signature', ENV['STRIPE_ENDPOINT_SECRET'])
      subject
    end
  end

  describe '#process_webhook_event' do
    let(:event) { double('event', type: 'checkout.session.completed', data: 'data') }
    subject { controller.send(:process_webhook_event, event) }
    it do
      expect(controller).to receive(:process_checkout_session_completed).with('data')
      subject
    end
  end
end
