require 'rails_helper'

RSpec.describe Egotter::SortedSet do
  let(:instance) { described_class.new(Redis.client) }
  let(:default_ttl) { 60 }

  before do
    Redis.client.flushdb
    instance.instance_variable_set(:@key, 'key')
    instance.instance_variable_set(:@ttl, default_ttl)
  end

  describe '#ttl' do
    subject { instance.ttl(val) }

    context 'val == nil' do
      let(:val) { nil }
      it { is_expected.to eq(default_ttl) }
    end

    context 'val != nil' do
      let(:val) { 123 }

      context "The set includes specified value" do
        before { instance.add(val) }
        it do
          expect(instance.ttl(val)).to eq(default_ttl)
          travel 10.seconds
          expect(instance.ttl(val)).to eq(default_ttl - 10)
        end
      end

      context "The set doesn't include specified value" do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '#exists?' do
    let(:val) { 123 }
    subject { instance.exists?(val) }

    context "The set includes specified value" do
      before { instance.add(val) }
      it { is_expected.to eq(true) }
    end

    context "The set doesn't include specified value" do
      it { is_expected.to eq(false) }
    end
  end

  describe '#add' do
    let(:val) { 123 }
    subject { instance.add(val) }

    it do
      expect { instance.add(val) }.to change { instance.size }.by(1)
      expect { instance.add(val) }.not_to change { instance.size }
      expect { instance.add(val + 1) }.to change { instance.size }.by(1)
    end
  end

  describe '#to_a' do
    subject { instance.to_a }

    it do
      expect(instance.to_a).to eq([])
      instance.add(1)
      expect(instance.to_a).to eq(['1'])
      instance.add(2)
      expect(instance.to_a).to eq(['1', '2'])

      travel default_ttl + 1.second

      expect(instance.to_a).to eq([])
    end
  end
end
