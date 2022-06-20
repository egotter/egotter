require 'rails_helper'

RSpec.describe ProcessStripeCheckoutSessionCompletedEventWorker do
  let(:worker) { described_class.new }
  let(:checkout_session_id) { 'cs_xxxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  before do
    allow(worker).to receive(:send_message).with(:orders_cs_completed, an_instance_of(String), checkout_session_id, user_id: user.id, order_id: order.id)
  end

  describe '#perform' do
    let(:checkout_session) { double('checkout_session', client_reference_id: user.id) }
    subject { worker.perform(checkout_session_id) }
    before do
      allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      allow(user).to receive(:has_valid_subscription?)
    end
    it do
      expect(Stripe::Checkout::Session).to receive(:retrieve).with(checkout_session_id).and_return(checkout_session)
      expect(Order).to receive(:create_by_checkout_session).with(checkout_session).and_return(order)
      expect(worker).to receive(:update_trial_end_and_email).with(order)
      subject
    end
  end
end
