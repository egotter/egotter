require 'rails_helper'

RSpec.describe ServiceStatus, type: :model do
  describe '#connection_reset_by_peer?' do
    let(:ex) { RuntimeError.new('Connection reset by peer') }
    subject { described_class.new(ex: ex).connection_reset_by_peer? }
    it { is_expected.to be_truthy }
  end

  describe '#internal_server_error?' do
    let(:ex) { Twitter::Error::InternalServerError.new('Internal error') }
    subject { described_class.new(ex: ex).internal_server_error? }
    it { is_expected.to be_truthy }
  end

  describe '#service_unavailable?' do
    let(:ex) { Twitter::Error::ServiceUnavailable.new('Over capacity') }
    subject { described_class.new(ex: ex).service_unavailable? }
    it { is_expected.to be_truthy }
  end

  describe '#execution_expired?' do
    let(:ex) { Twitter::Error.new('execution expired') }
    subject { described_class.new(ex: ex).execution_expired? }
    it { is_expected.to be_truthy }
  end

  describe '#retryable_error?' do
    let(:ex) { RuntimeError.new('Anything') }
    let(:status) { described_class.new(ex: ex) }
    subject { status.retryable_error? }

    it do
      expect(status).to receive(:connection_reset_by_peer?).with(no_args).and_return(false)
      expect(status).to receive(:internal_server_error?).with(no_args).and_return(false)
      expect(status).to receive(:service_unavailable?).with(no_args).and_return(false)
      expect(status).to receive(:execution_expired?).with(no_args).and_return(true)
      is_expected.to be_truthy
    end
  end

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
end
