require 'rails_helper'

RSpec.describe PermissionLevelClient, type: :model do
  describe '#permission_level' do
    subject { described_class.new('client').permission_level }
    before do
      allow(described_class::Request).to receive(:new).with(any_args).and_raise('Error')
      allow(ServiceStatus).to receive(:retryable_error?).with(any_args).and_return(true)
    end
    it { expect { subject }.to raise_error(described_class::RetryExhausted) }
  end
end
