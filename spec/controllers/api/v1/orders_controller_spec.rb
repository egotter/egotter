require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:user) { create(:user, with_orders: true) }
  let(:order) { user.orders.last }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    subject { get :index, params: {} }

    context 'User has a valid subscription' do
      before { allow(user).to receive(:has_valid_subscription?).and_return(true) }
      it do
        is_expected.to have_http_status(:ok)
        expect(JSON.parse(response.body)['subscription']).to be_truthy
      end
    end

    context 'User does not have a valid subscription' do
      before { allow(user).to receive(:has_valid_subscription?).and_return(false) }
      it do
        is_expected.to have_http_status(:ok)
        expect(JSON.parse(response.body)['subscription']).to be_falsey
      end
    end
  end

  describe 'POST #end_trial' do
    subject { post :end_trial, params: {} }
    before { allow(user).to receive(:valid_order).and_return(order) }

    context 'The order is trialing' do
      before { allow(order).to receive(:trial?).and_return(true) }
      it do
        expect(order).to receive(:end_trial!)
        expect(controller).to receive(:send_message).with('Success', order_id: order.id)
        is_expected.to have_http_status(:ok)
      end
    end

    context 'The order is NOT trialing' do
      before { allow(order).to receive(:trial?).and_return(false) }
      it do
        expect(order).not_to receive(:end_trial!)
        expect(controller).to receive(:send_message).with('Not trialing', order_id: order.id)
        is_expected.to have_http_status(:bad_request)
      end
    end

    context 'An error is raised' do
      let(:error) { RuntimeError.new }
      before { allow(order).to receive(:trial?).and_raise(error) }
      it do
        expect(Airbag).to receive(:exception).with(error, user_id: user.id)
        is_expected.to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to be_truthy
      end
    end
  end

  describe 'POST #cancel' do
    subject { post :cancel, params: {id: order.id} }
    before { allow(user.orders).to receive(:find_by).with(id: order.id.to_s).and_return(order) }

    context 'The order is already canceled' do
      before { allow(order).to receive(:canceled?).and_return(true) }
      it do
        expect(order).not_to receive(:cancel!)
        expect(controller).to receive(:send_message).with('Already canceled', order_id: order.id)
        is_expected.to have_http_status(:bad_request)
      end
    end

    context 'The order is NOT canceled' do
      before { allow(order).to receive(:canceled?).and_return(false) }
      it do
        expect(order).to receive(:cancel!).with('user')
        expect(controller).to receive(:send_message).with('Success', order_id: order.id)
        is_expected.to have_http_status(:ok)
      end
    end

    context 'An error is raised' do
      let(:error) { RuntimeError.new }
      before { allow(order).to receive(:canceled?).and_raise(error) }
      it do
        expect(Airbag).to receive(:exception).with(error, user_id: user.id)
        is_expected.to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to be_truthy
      end
    end
  end

  describe '#send_message' do
    subject { controller.send(:send_message, 'msg', order_id: 1) }
    before { allow(controller).to receive(:tracking_channel).and_return('channel') }
    it do
      expect(SendOrderMessageToSlackWorker).to receive(:perform_async).with('channel', /msg/)
      subject
    end
  end
end
