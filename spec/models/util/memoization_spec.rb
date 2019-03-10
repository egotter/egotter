require 'rails_helper'

RSpec.describe Util::Memoization do
  let(:dummy_class) do
    Class.new do
      extend Util::Memoization
    end
  end

  describe '.valid_ivar_name' do
    it "doesn't remove '_'" do
      expect(dummy_class.valid_ivar_name('is_valid')).to eq('is_valid')
    end

    it 'removes "?"' do
      expect(dummy_class.valid_ivar_name('valid?')).to eq('valid')
    end

    it 'removes "!"' do
      expect(dummy_class.valid_ivar_name('valid!')).to eq('valid')
    end
  end

  describe '.memoize' do
    before do
      dummy_class.send(:define_method, :hello) { 'hello' }
      dummy_class.send(:memoize)
    end

    it do
      expect(dummy_class.new.respond_to?(:hello)).to be_truthy
      expect(dummy_class.new.respond_to?("#{described_class::MEMOIZE_PREFIX}hello")).to be_truthy
    end
  end
end
