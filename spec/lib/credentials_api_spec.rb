require 'rails_helper'

RSpec.describe CredentialsApi, type: :model do

end

RSpec.describe CredentialsApi::RateLimitClient, type: :model do
  describe '#rate_limit' do
    subject { described_class.new('client').rate_limit }
    before do
      allow(Twitter::REST::Request).to receive(:new).with(any_args).and_raise('Error')
      allow(ServiceStatus).to receive(:retryable_error?).with(any_args).and_return(true)
    end
    it { expect { subject }.to raise_error(described_class::RetryExhausted) }
  end
end
