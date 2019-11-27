require 'rails_helper'

RSpec.describe Egotter::SortedSet do
  describe '#ttl' do
    let(:instance) { described_class.new(Redis.client) }
    subject { instance.ttl(val) }

    before { instance.instance_variable_set(:@ttl, 60) }

    context 'val == nil' do
      let(:val) { nil }
      it { is_expected.to eq(60) }
    end

    context 'val != nil' do
      let(:val) { 123 }
      before { instance.add(123) }
      it do
        travel 10.seconds do
          is_expected.to eq(60 - 10)
        end
      end
    end
  end
end
