require 'rails_helper'

RSpec.describe UpdateCustomerEmailWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:customer) { create(:customer, user_id: user.id) }
    let(:stripe_customer) { double('stripe_customer', email: 'changed@example.com') }
    subject { worker.perform(user.id) }
    before do
      allow(Customer).to receive(:find_by).with(user_id: user.id).and_return(customer)
      allow(customer).to receive(:stripe_customer).and_return(stripe_customer)
      user.email = 'user@example.com'
    end

    it do
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(:customers, instance_of(String))
      subject
    end
  end
end
