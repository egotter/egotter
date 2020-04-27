require 'rails_helper'

RSpec.describe Efs::FavoriteTweet do
  describe '.delete' do
    subject { described_class.delete(uid: 1) }
    it do
      expect(described_class.client).to receive(:delete).with(1)
      subject
    end
  end
end
