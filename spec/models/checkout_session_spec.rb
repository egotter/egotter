require 'rails_helper'

RSpec.describe CheckoutSession, type: :model do
  let(:user) { create(:user) }

  describe '.expire_all' do
    let(:stripe_checkout_session) { double('scs', status: 'open') }
    let(:checkout_sessions) { [create(:checkout_session, user_id: user.id), create(:checkout_session, user_id: user.id + 1)] }
    subject { described_class.expire_all(user.id) }
    before do
      allow(Stripe::Checkout::Session).to receive(:retrieve).
          with(checkout_sessions[0].stripe_checkout_session_id).and_return(stripe_checkout_session)
    end
    it do
      expect(Stripe::Checkout::Session).to receive(:expire).with(checkout_sessions[0].stripe_checkout_session_id)
      expect(Stripe::Checkout::Session).not_to receive(:expire).with(checkout_sessions[1].stripe_checkout_session_id)
      subject
    end
  end
end
