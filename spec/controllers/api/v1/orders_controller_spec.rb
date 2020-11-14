require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #end_trial' do
    subject { post :end_trial, params: {} }
    before { allow(user).to receive(:valid_order).and_return(order) }
    it do
      expect(order).to receive(:end_trial!)
      expect(controller).to receive(:send_message).with(order)
      is_expected.to have_http_status(:ok)
    end
  end

  describe 'POST #cancel' do
    let(:orders) { double('orders') }
    subject { post :cancel, params: {id: order.id} }
    before do
      allow(user).to receive(:orders).and_return(orders)
      allow(orders).to receive(:find_by).with(id: order.id.to_s).and_return(order)
    end
    it do
      expect(order).to receive(:cancel!)
      expect(controller).to receive(:send_message).with(order)
      is_expected.to have_http_status(:ok)
    end
  end
end
