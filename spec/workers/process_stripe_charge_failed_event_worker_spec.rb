require 'rails_helper'

RSpec.describe ProcessStripeChargeFailedEventWorker do
  let(:worker) { described_class.new }
  let(:customer_id) { 'cus_xxxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id, customer_id: customer_id) }

  describe '#perform' do
    subject { worker.perform(customer_id) }
    before do
      allow(Order).to receive(:where).with(customer_id: customer_id, canceled_at: nil, charge_failed_at: nil).and_return([order])
    end
    it do
      expect(order).to receive(:update!).with(charge_failed_at: instance_of(ActiveSupport::TimeWithZone))
      expect(order).to receive(:cancel!).with('webhook')
      expect(worker).to receive(:send_message).with(/Success/)
      subject
    end
  end
end
