require 'rails_helper'

RSpec.describe Efs::FavoriteTweet do
  describe '.delete' do
    it do
      expect(described_class.cache).to receive(:delete_object).with(1)
      described_class.delete(uid: 1)
    end
  end
end
