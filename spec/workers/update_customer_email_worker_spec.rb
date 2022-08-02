require 'rails_helper'

RSpec.describe UpdateCustomerEmailWorker do
  let(:user) { create(:user, email: 'user@example.com') }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    let(:customer) { create(:customer, user_id: user.id) }
    let(:stripe_customer) { double('stripe_customer', email: 'changed@example.com') }
    subject { worker.perform(user.id) }
    before do
      allow(Customer).to receive(:find_by).with(user_id: user.id).and_return(customer)
      allow(customer).to receive(:stripe_customer).and_return(stripe_customer)
    end

    it do
      expect(user).to receive(:update).with(email: stripe_customer.email)
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(:customers, instance_of(String))
      subject
    end
  end
end
