require 'rails_helper'

RSpec.describe Followership, type: :model do
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
      expect { Followership.import_from!(twitter_user) }.to change { Followership.all.size }.by(twitter_user.followers.size)

      twitter_user.reload
      expect(twitter_user.tmp_followers.map(&:uid)).to eq(twitter_user.followers.pluck(:uid).map(&:to_i))
    end
  end
end
