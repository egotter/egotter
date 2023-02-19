require 'rails_helper'

RSpec.describe ProcessStripeChargeSucceededEventWorker do
  let(:worker) { described_class.new }
  let(:customer_id) { 'cus_xxxx' }
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id, customer_id: customer_id) }

  describe '#perform' do
    subject { worker.perform(customer_id) }
    before do
      allow(Order).to receive_message_chain(:select, :where).with(:id, :user_id).
          with(customer_id: customer_id).and_return([order])
    end
    it do
      expect(worker).to receive(:send_message).with(/Success/)
      subject
    end
  end
end
