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
      expect(controller).to receive(:build_checkout_session_attrs).with(user).and_return('attrs')
      expect(Stripe::Checkout::Session).to receive(:create).with('attrs').and_return(checkout_session)
      post :create
      expect(JSON.parse(response.body)['session_id']).to eq(checkout_session.id)
    end
  end

  describe ' #build_checkout_session_attrs' do
    subject { controller.send(:build_checkout_session_attrs, user) }
    it { is_expected.to be_truthy }

    context 'user has customer_id' do
      before { allow(user).to receive(:valid_customer_id).and_return('cus_xxxx') }
      it { is_expected.to be_truthy }
    end
  end
end
