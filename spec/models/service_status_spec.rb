require 'rails_helper'

RSpec.describe ServiceStatus, type: :model do
  describe '.connection_reset_by_peer?' do
    let(:ex) { RuntimeError.new('Connection reset by peer') }
    subject { described_class.connection_reset_by_peer?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.internal_server_error?' do
    let(:ex) { Twitter::Error::InternalServerError.new('Internal error') }
    subject { described_class.internal_server_error?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.service_unavailable?' do
    let(:ex) { Twitter::Error::ServiceUnavailable.new('Over capacity') }
    subject { described_class.service_unavailable?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.execution_expired?' do
    let(:ex) { Twitter::Error.new('execution expired') }
    subject { described_class.execution_expired?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.retryable_error?' do
    let(:ex) { RuntimeError.new('Anything') }
    subject { described_class.retryable_error?(ex) }

    it do
      expect(described_class).to receive(:connection_reset_by_peer?).with(ex)
      expect(described_class).to receive(:internal_server_error?).with(ex)
      expect(described_class).to receive(:service_unavailable?).with(ex)
      expect(described_class).to receive(:execution_expired?).with(ex)
      subject
    end
  end
end
