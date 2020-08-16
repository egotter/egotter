require 'rails_helper'

RSpec.describe CreatePeriodicTweetRequest, type: :model do
  context 'validation' do
    it do
      expect(described_class.new.valid?).to be_falsey
      expect(described_class.new(user_id: 1).valid?).to be_truthy
    end
  end
end
