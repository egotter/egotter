require 'rails_helper'

RSpec.describe CacheLoader, type: :model do
  let(:records) { [Object.new, Object.new, Object.new] }
  let(:timeout) { 10.seconds }
  let(:concurrency) { 2 }
  let(:block) { Proc.new { |record| record.inspect } }
  let(:instance) do
    CacheLoader.new(records, timeout: timeout, concurrency: concurrency, &block)
  end

  describe '#load' do
    subject { instance.load }

    it do
      records.each { |r| expect(r).to receive(:inspect) }
      subject
    end

    context '#timeout? returns true' do
      before { allow(instance).to receive(:timeout?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::Timeout) }
    end

    context '#timeout? returns false' do
      before { allow(instance).to receive(:timeout?).and_return(false) }
      it { expect { subject }.to_not raise_error }
    end
  end

  describe '#timeout?' do
    subject { instance.timeout? }
    before { instance.instance_variable_set(:@start, 1.day.ago) }
    it { is_expected.to be_truthy }
  end
end
