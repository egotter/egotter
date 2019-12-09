require 'rails_helper'

RSpec.describe OrdersController, type: :controller do

  describe 'POST #create' do
    let(:user) { create(:user) }
    let(:stripeEmail) { 'a@a.com' }
    let(:stripeToken) { 'token' }
    subject { post :create, params: {stripeEmail: stripeEmail, stripeToken: stripeToken} }

    context 'The user is not signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).with(no_args).and_return(false)
      end
      it do
        expect(controller).to receive(:require_login!).with(no_args).and_call_original
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'The user has already purchased a plan' do
      before do
        allow(user).to receive(:has_valid_subscription?).with(no_args).and_return(true)
        allow(controller).to receive(:current_user).with(no_args).and_return(user)
        allow(controller).to receive(:require_login!).with(no_args).and_return(nil)
      end
      it do
        expect(controller).to receive(:has_already_purchased?).with(no_args).and_call_original
        subject
        expect(response).to have_http_status(:found)
      end
    end

    context 'The user is signed in and a valid request is coming' do
      let(:order) { create(:order, user_id: user.id) }
      let(:customer) { double('Customer', id: 'customer_id') }
      let(:subscription) { double('Subscription', id: 'subscription_id') }

      before do
        allow(user).to receive(:has_valid_subscription?).with(no_args).and_return(false)
        allow(user).to receive_message_chain(:orders, :last).with(no_args).with(no_args).and_return(order)
        allow(controller).to receive(:current_user).with(no_args).and_return(user)
        allow(controller).to receive(:send_message_to_slack).with(any_args).and_return(nil)
        allow(subscription).to receive_message_chain(:items, :data, :[], :plan, :nickname).with(no_args).with(no_args).with(:'0').with(no_args).with(no_args).and_return('plan name')
        allow(subscription).to receive_message_chain(:items, :data, :[], :plan, :amount).with(no_args).with(no_args).with(:'0').with(no_args).with(no_args).and_return(100)
      end

      it do
        expect(user).to receive_message_chain(:orders, :create!).with(no_args).with(email: stripeEmail).and_return(order)
        expect(Stripe::Customer).to receive(:create).with(email: stripeEmail, source: stripeToken, metadata: {order_id: order.id}).and_return(customer)
        expect(order).to receive(:update!).with(customer_id: customer.id).and_call_original
        expect(Stripe::Subscription).to receive(:create).with(customer: customer.id, items: [{plan: ENV['STRIPE_BASIC_PLAN_ID']}], metadata: {order_id: order.id}).and_return(subscription)
        expect(order).to receive(:update!).with(subscription_id: subscription.id, name: 'plan name', price: 100, search_count: SearchCountLimitation::BASIC_PLAN, follow_requests_count: CreateFollowLimitation::BASIC_PLAN, unfollow_requests_count: CreateUnfollowLimitation::BASIC_PLAN).and_call_original
        subject
        expect(response).to have_http_status(:found)
        is_expected.to redirect_to root_path
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }
    let(:order) { create(:order, user_id: user.id) }
    subject { delete :destroy, params: {id: order.id} }

    before do
      allow(controller).to receive(:current_user).with(no_args).and_return(user)
      allow(order).to receive(:cancel!).with(no_args)
      allow(controller).to receive(:send_message_to_slack).with(any_args).and_return(nil)
    end

    it do
      subject
      expect(response).to have_http_status(:found)
      is_expected.to redirect_to root_path
    end
  end
end
