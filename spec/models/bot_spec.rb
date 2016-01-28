require 'rails_helper'

RSpec.describe Bot, type: :model do
  describe '.init' do
    it 'returns true' do
      expect(Bot.init).to be_nil
    end
  end

  describe '.sample' do
    it 'returns true' do
      expect(Bot.sample).to be_truthy
    end
  end

  describe '.size' do
    it 'returns true' do
      expect(Bot.size).to be_truthy
    end
  end

  describe '.empty?' do
    it 'returns false' do
      expect(Bot.empty?).to be_falsey
    end
  end
end
