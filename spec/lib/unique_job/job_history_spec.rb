require 'rails_helper'

RSpec.describe UniqueJob::JobHistory do
  let(:instance) { described_class.new(Class, Class, 1.minute) }

  before { Redis.client.flushdb }

  describe '#exists?' do
    let(:val) { 'value' }
    subject { instance.exists?(val) }

    it { is_expected.to be_falsey }

    context 'history includes value' do
      before { instance.add(val) }
      it { is_expected.to be_truthy }
    end
  end

  describe '#add' do
    let(:val) { 'value' }
    let(:redis) { instance.instance_variable_get(:@redis) }
    subject { instance.add(val) }
    before { allow(instance).to receive(:key).with(val).and_return('key') }
    it do
      expect(redis).to receive(:setex).with('key', 1.minute, true).and_call_original
      subject
      expect(redis.get('key')).to eq('true')
      expect(redis.ttl('key')).to eq(60)
    end
  end

  describe '#key' do
    let(:val) { 'value' }
    subject { instance.send(:key, val) }
    it { is_expected.to eq("UniqueJob::JobHistory:Class:Class:value") }
  end
end
