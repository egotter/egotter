require 'rails_helper'

RSpec.describe TwitterDB::Followership, type: :model do
  let(:twitter_user) { create(:twitter_user) }
  before do
    twitter_user
    [TwitterDB::Friendship, TwitterDB::Followership, TwitterDB::User].each { |klass| klass.delete_all }
    [Friendship, Followership].each { |klass| klass.delete_all }
  end

  describe '.import_from!' do
    before do
      TwitterDB::User.import_from! ([twitter_user] + twitter_user.followers)
    end
    it 'creates followerships' do
      expect { TwitterDB::Followership.import_from!(twitter_user) }.to change { TwitterDB::Followership.all.size }.by(twitter_user.followers.size)

      user = TwitterDB::User.find_by(uid: twitter_user.uid)
      expect(user.followers.pluck(:uid)).to eq(twitter_user.followers.pluck(:uid).map(&:to_i))
    end
  end
end
