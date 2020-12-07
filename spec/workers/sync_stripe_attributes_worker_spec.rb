require 'rails_helper'

RSpec.describe SyncStripeAttributesWorker do
  let(:user) { create(:user, with_orders: true) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:order) { user.orders.last }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
    end

    it do
      expect(order).to receive(:sync_stripe_attributes!)
      subject
    end
  end
end
