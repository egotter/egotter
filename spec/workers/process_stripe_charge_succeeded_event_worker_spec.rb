require 'rails_helper'

RSpec.describe ProcessStripeChargeSucceededEventWorker do
  let(:worker) { described_class.new }
  let(:customer_id) { 'cus_xxxx' }
  let(:user) { create(:user) }

  describe '#perform' do
    subject { worker.perform(customer_id) }
    before { create(:order, user_id: user.id, customer_id: customer_id) }
    it do
      allow(worker).to receive(:send_message).with(/Success/)
      subject
    end
  end
end
