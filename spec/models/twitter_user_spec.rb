require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  let(:user) { create(:twitter_user, with_relations: true) }

  describe '#status_tweets' do
    it 'has many status_tweets' do
      expect(user.status_tweets.size).to eq(2) # TODO Tightly coupled with factory
    end
  end

  describe '#favorite_tweets' do
    it 'has many favorite_tweets' do
      expect(user.favorite_tweets.size).to eq(2) # TODO Tightly coupled with factory
    end
  end

  describe '#mention_tweets' do
    it 'has many mention_tweets' do
      expect(user.mention_tweets.size).to eq(2) # TODO Tightly coupled with factory
    end
  end

  describe '#friends_count' do
    it do
      expect(Efs::TwitterUser).not_to receive(:find_by)
      user.friends_count
    end
  end

  describe '#followers_count' do
    it do
      expect(Efs::TwitterUser).not_to receive(:find_by)
      user.followers_count
    end
  end
end
