require 'rails_helper'

RSpec.describe UpdateTrialEndWorker do
  let(:user) { create(:user, with_orders: true) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:order) { user.orders.last }
    let(:customer) { double('customer', email: 'a@b.com') }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
      allow(order).to receive(:fetch_stripe_customer).and_return(customer)
    end

    it do
      expect(order).to receive(:sync_trial_end!)
      subject
      order.reload
      expect(order.email).to eq('a@b.com')
    end
  end
end
