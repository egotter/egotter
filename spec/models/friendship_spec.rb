require 'rails_helper'

RSpec.describe Friendship, type: :model do
  let(:twitter_user) { create(:twitter_user) }
  before do
    twitter_user
    [TwitterDB::Friendship, TwitterDB::Followership, TwitterDB::User].each { |klass| klass.delete_all }
    [Friendship, Followership].each { |klass| klass.delete_all }
  end

  describe '.import_from!' do
    before do
      TwitterDB::User.import_from! ([twitter_user] + twitter_user.friends)
    end
    it 'creates friendships' do
      expect { Friendship.import_from!(twitter_user) }.to change { Friendship.all.size }.by(twitter_user.friends.size)

      twitter_user.reload
      expect(twitter_user.tmp_friends.map(&:uid)).to eq(twitter_user.friends.pluck(:uid).map(&:to_i))
    end
  end
end
