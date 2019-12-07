require 'rails_helper'

RSpec.describe TooManyRequestsUsers, type: :model do
    describe '#ttl' do
    it do
      expect(TooManyRequestsUsers.new.ttl).to eq(60 * 15)
    end
  end
end
