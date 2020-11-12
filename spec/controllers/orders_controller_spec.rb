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

  describe 'DELETE #destroy' do
    subject { delete :destroy, params: {id: order.id} }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:send_message_to_slack)
      allow(controller).to receive(:fetch_order).and_return(order)
    end

    context 'canceled_at is blank' do
      before { order.update!(canceled_at: Time.zone.now) }
      it do
        expect(order).not_to receive(:cancel!)
        subject
        is_expected.to redirect_to root_path(via: 'orders/destroy/already_canceled')
      end
    end

    context 'canceled_at is present' do
      it do
        expect(order).to receive(:cancel!)
        subject
        is_expected.to redirect_to root_path(via: 'orders/destroy')
      end
    end
  end

  describe '#send_message_to_slack' do
    subject { controller.send(:send_message_to_slack) }
    before { allow(controller).to receive(:fetch_order).and_return(order) }
    it do
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(:orders, "order=#{order.inspect}", instance_of(String))
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

    context 'action is #destroy' do
      let(:action) { 'destroy' }
      before { allow(controller).to receive_message_chain(:params, :[]).with(:id).and_return(1) }
      it do
        expect(controller).to receive_message_chain(:current_user, :orders, :find_by).with(id: 1).and_return('result')
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
