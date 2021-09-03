require 'rails_helper'

RSpec.describe SyncOrderEmailWorker do
  let(:user) { create(:user) }
  let(:order) { create(:order, user_id: user.id) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:new_email) { 'new@example.com' }
    subject { worker.perform(order.id) }

    before do
      allow(Order).to receive(:find).with(order.id).and_return(order)
      allow(worker).to receive(:fetch_customer_email).with(order.customer_id).and_return(new_email)
    end

    it do
      expect(worker).to receive(:send_message).with(order.id, [order.email, new_email])
      subject
      order.reload
      expect(order.email).to eq(new_email)
    end
  end
end