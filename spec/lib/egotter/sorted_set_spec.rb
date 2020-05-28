require 'rails_helper'

RSpec.describe Egotter::SortedSet do
  let(:instance) { described_class.new(Redis.client) }

  before do
    Redis.client.flushdb
    instance.instance_variable_set(:@key, 'key')
    instance.instance_variable_set(:@ttl, 60)
  end

  describe '#ttl' do
    subject { instance.ttl(val) }

    context 'val == nil' do
      let(:val) { nil }
      it { is_expected.to eq(60) }
    end

    context 'val != nil' do
      let(:val) { 123 }

      context "The set includes specified value" do
        before { instance.add(val) }
        it do
          expect(instance.ttl(val)).to eq(60)
          travel 10.seconds
          expect(instance.ttl(val)).to eq(60 - 10)
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
      it { is_expected.to be_truthy }
    end

    context "The set doesn't include specified value" do
      it { is_expected.to be_falsey }
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

  end
end
