require 'rails_helper'

RSpec.describe Concerns::Logging do
  let(:klass) { Class.new.extend(Concerns::Logging) }
  let(:referers) { %w(http://t.co/aaa http://egotter.com) }

  describe '#find_referral' do
    it 'returns referral' do
      expect(klass.send(:find_referral, referers)).to eq 't.co'
    end
  end

  describe '#find_channel' do
    it 'returns channel' do
      expect(klass.send(:find_channel, 't.co')).to eq 'twitter'
    end
  end
end
