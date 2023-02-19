require 'rails_helper'

RSpec.describe ProcessStripeChargeFailedEventWorker do
  let(:worker) { described_class.new }
  let(:customer_id) { 'cus_xxxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id, customer_id: customer_id) }

  before do
    allow(worker).to receive(:send_message).with(anything)
  end

  describe '#perform' do
    subject { worker.perform(customer_id) }
    before do
      allow(Order).to receive(:find_by_customer_id).with(customer_id).and_return(order)
    end
    it do
      expect(order).to receive(:update!).with(charge_failed_at: instance_of(ActiveSupport::TimeWithZone))
      expect(order).to receive(:cancel!).with('webhook')
      subject
    end
  end
end
