require 'rails_helper'

RSpec.describe Api::V1::CheckoutSessionsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:require_login!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    let(:checkout_session) { double('checkout_session', id: 1, customer: 'cus_xxxx', metadata: {}) }
    it do
      expect(StripeCheckoutSession).to receive(:create).with(user).and_return(checkout_session)
      post :create
      expect(JSON.parse(response.body)['session_id']).to eq(checkout_session.id)
    end
  end
end
