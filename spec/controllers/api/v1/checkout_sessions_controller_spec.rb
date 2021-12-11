require 'rails_helper'

RSpec.describe Api::V1::CheckoutSessionsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:require_login!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    let(:stripe_session) { double('stripe_session', id: 1) }
    it do
      expect(controller).to receive(:create_session).with(user).and_return(stripe_session)
      post :create
      expect(JSON.parse(response.body)['session_id']).to eq(stripe_session.id)
    end
  end

  describe '#create_session' do
    let(:stripe_session) { double('stripe_session', id: 1) }
    subject { controller.send(:create_session, user) }
    before { allow(controller).to receive(:params).and_return(button_id: 'id') }
    it do
      expect(CheckoutSessionBuilder).to receive(:build).with(user).and_return('hash')
      expect(Stripe::Checkout::Session).to receive(:create).with('hash').and_return(stripe_session)
      expect(CheckoutSession).to receive(:create!).with(user_id: user.id, stripe_checkout_session_id: stripe_session.id, properties: {button_id: 'id'})
      is_expected.to eq(stripe_session)
    end
  end
end
