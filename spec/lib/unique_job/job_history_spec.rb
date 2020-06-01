require 'rails_helper'

RSpec.describe UniqueJob::JobHistory do
  let(:instance) { described_class.new(Class, Class, 1.minute) }
  let(:redis) { instance.instance_variable_get(:@redis) }

  before { Redis.client.flushdb }

  describe '#exists?' do
    let(:val) { 'value' }
    subject { instance.exists?(val) }

    it { is_expected.to be_falsey }

    context 'history includes value' do
      before { instance.add(val) }
      it { is_expected.to be_truthy }
    end

    context '@redis raises an exception' do
      before { allow(redis).to receive(:exists).with(any_args).and_raise('error') }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#add' do
    let(:val) { 'value' }
    subject { instance.add(val) }

    before { allow(instance).to receive(:key).with(val).and_return('key') }

    it do
      expect(redis).to receive(:setex).with('key', 1.minute, true).and_call_original
      subject
      expect(redis.get('key')).to eq('true')
      expect(redis.ttl('key')).to eq(60)
    end

    context '@redis raises an exception' do
      before { allow(redis).to receive(:setex).with(any_args).and_raise('error') }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#key' do
    let(:val) { 'value' }
    subject { instance.send(:key, val) }
    it { is_expected.to eq("UniqueJob::JobHistory:Class:Class:value") }
  end
end
