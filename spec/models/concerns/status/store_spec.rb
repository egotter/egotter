require 'rails_helper'

RSpec.describe Concerns::Status::Store do
  let(:status) { build(:mention_status) }

  describe '#retweet?' do
    it 'returns false' do
      expect(status.retweet?).to be_falsy
    end
  end

  describe '#mention_uids' do
    it 'returns [1001668814]' do
      expect(status.mention_uids).to match_array([1001668814])
    end
  end

  describe '#mention_to?' do
    it 'returns true' do
      expect(status.mention_to? '@PoyoMetal').to be_truthy
    end
  end
end
