require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  let(:user) { create(:twitter_user) }

  describe '#statuses' do
    it 'has many statuses' do
      expect(user.statuses.size).to eq(2) # TODO Tightly coupled with factory
    end
  end

  describe '#favorites' do
    it 'has many favorites' do
      expect(user.favorites.size).to eq(2) # TODO Tightly coupled with factory
    end
  end

  describe '#mentions' do
    it 'has many mentions' do
      expect(user.mentions.size).to eq(2) # TODO Tightly coupled with factory
    end
  end
end
