require 'rails_helper'

RSpec.describe ServiceStatus, type: :model do
  let(:status) { described_class.new(ex: ex) }

  describe '#connection_reset_by_peer?' do
    let(:ex) { RuntimeError.new('Connection reset by peer') }
    it { expect(status.connection_reset_by_peer?).to be_truthy }
  end

  describe '#internal_server_error?' do
    let(:ex) { Twitter::Error::InternalServerError.new('Internal error') }
    it { expect(status.internal_server_error?).to be_truthy }
  end

  describe '#service_unavailable?' do
    let(:ex) { Twitter::Error::ServiceUnavailable.new('Over capacity') }
    it { expect(status.service_unavailable?).to be_truthy }
  end

  describe '#execution_expired?' do
    let(:ex) { Twitter::Error.new('execution expired') }
    it { expect(status.execution_expired?).to be_truthy }
  end

  describe '#retryable?' do
    let(:ex) { RuntimeError.new('Anything') }
    it do
      expect(status).to receive(:connection_reset_by_peer?).with(no_args).and_return(false)
      expect(status).to receive(:internal_server_error?).with(no_args).and_return(false)
      expect(status).to receive(:service_unavailable?).with(no_args).and_return(false)
      expect(status).to receive(:execution_expired?).with(no_args).and_return(true)
      expect(status.retryable?).to be_truthy
    end
  end
end
