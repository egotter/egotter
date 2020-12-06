require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  # describe 'POST #create' do
  #   let(:stripeEmail) { 'a@a.com' }
  #   let(:stripeToken) { 'token' }
  #   subject { post :create, params: {stripeEmail: stripeEmail, stripeToken: stripeToken} }
  #
  #   context 'The user is not signed in' do
  #     before { allow(controller).to receive(:user_signed_in?).and_return(false) }
  #     it do
  #       expect(controller).to receive(:require_login!).and_call_original
  #       subject
  #       expect(response).to have_http_status(:unauthorized)
  #     end
  #   end
  #
  #   context 'The user has already purchased a plan' do
  #     before do
  #       allow(user).to receive(:has_valid_subscription?).and_return(true)
  #       allow(controller).to receive(:current_user).and_return(user)
  #       allow(controller).to receive(:require_login!)
  #     end
  #     it do
  #       expect(controller).to receive(:has_already_purchased?).and_call_original
  #       subject
  #       expect(response).to have_http_status(:found)
  #     end
  #   end
  #
  #   context 'The user is signed in and a valid request is coming' do
  #     let(:customer) { double('Customer', id: 'customer_id') }
  #     let(:subscription) { double('Subscription', id: 'subscription_id') }
  #
  #     before do
  #       allow(user).to receive(:has_valid_subscription?)
  #       allow(user).to receive_message_chain(:orders, :last).and_return(order)
  #       allow(controller).to receive(:current_user).and_return(user)
  #       allow(controller).to receive(:send_message_to_slack)
  #       allow(subscription).to receive_message_chain(:items, :data, :[], :plan, :nickname).with(no_args).with(no_args).with(:'0').with(no_args).with(no_args).and_return('plan name')
  #       allow(subscription).to receive_message_chain(:items, :data, :[], :plan, :amount).with(no_args).with(no_args).with(:'0').with(no_args).with(no_args).and_return(100)
  #     end
  #
  #     it do
  #       expect(user).to receive_message_chain(:orders, :create!).with(no_args).with(email: stripeEmail).and_return(order)
  #       expect(Stripe::Customer).to receive(:create).with(email: stripeEmail, source: stripeToken, metadata: {order_id: order.id}).and_return(customer)
  #       expect(order).to receive(:update!).with(customer_id: customer.id).and_call_original
  #       expect(Stripe::Subscription).to receive(:create).with(customer: customer.id, items: [{plan: Order::BASIC_PLAN_ID}], metadata: {order_id: order.id}).and_return(subscription)
  #       expect(order).to receive(:update!).with(subscription_id: subscription.id, name: 'plan name', price: 100, search_count: SearchCountLimitation::BASIC_PLAN, follow_requests_count: CreateFollowLimitation::BASIC_PLAN, unfollow_requests_count: CreateUnfollowLimitation::BASIC_PLAN).and_call_original
  #       subject
  #       expect(response).to have_http_status(:found)
  #       is_expected.to redirect_to root_path
  #     end
  #   end
  # end

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

  describe '#send_message' do
    subject { controller.send(:send_message) }
    before { allow(controller).to receive(:fetch_order).and_return(order) }
    it do
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(:orders, instance_of(String))
      subject
    end
  end

  describe 'fetch_order' do
    subject { controller.send(:fetch_order) }
    before { allow(controller).to receive(:action_name).and_return(action) }

    context 'action is #create' do
      let(:action) { 'create' }
      it do
        expect(controller).to receive_message_chain(:current_user, :orders, :last).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'action is #checkout_session_completed' do
      let(:action) { 'checkout_session_completed' }
      before { order }
      it do
        expect(Order).to receive(:where).with(any_args).and_call_original
        is_expected.to eq(order)
      end
    end
  end
end
