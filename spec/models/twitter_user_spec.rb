require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  describe '#statuses' do
    let(:user) { create(:twitter_user) }
    it 'has many statuses' do
      expect(user.statuses.size).to eq(2) # TODO Tightly coupled with factory
    end
  end

  describe '#favorites' do
    let(:user) { create(:twitter_user) }
    it 'has many favorites' do
      expect(user.favorites.size).to eq(2) # TODO Tightly coupled with factory
    end
  end
end