require 'rails_helper'

RSpec.describe Memoization do
  let(:dummy_class) do
    Class.new do
      extend Memoization

      def initialize
        @call_count = 0
      end
    end
  end

  describe '.valid_memoize_ivar_name' do
    subject { dummy_class.valid_memoize_ivar_name(method_name) }

    context "it doesn't remove '_'" do
      let(:method_name) { 'is_valid' }
      it { is_expected.to eq('is_valid') }
    end

    context 'it removes "?"' do
      let(:method_name) { 'valid?' }
      it { is_expected.to eq('valid') }
    end

    context 'it removes "!"' do
      let(:method_name) { 'valid!' }
      it { is_expected.to eq('valid') }
    end
  end

  describe '.memoize' do
    let(:instance) { dummy_class.new }
    before do
      dummy_class.send(:define_method, :perform) { @call_count += 1 }
      dummy_class.send(:memoize)
    end

    it do
      expect(instance.perform).to eq(1)
      expect(instance.perform).to eq(1)
      expect(instance.respond_to?("#{described_class::MEMOIZE_PREFIX}perform")).to be_truthy
    end
  end
end
