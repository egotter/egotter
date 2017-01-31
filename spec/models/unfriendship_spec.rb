require 'rails_helper'

RSpec.describe Unfriendship, type: :model do
  let(:twitter_user) { create(:twitter_user) }
  before do
    twitter_user
    [TwitterDB::Friendship, TwitterDB::Followership, TwitterDB::User].each { |klass| klass.delete_all }
    [Unfriendship, Unfollowership].each { |klass| klass.delete_all }
  end

  describe '.import_from!' do
    before do
      twitter_user.update!(created_at: twitter_user.created_at - 1.day, updated_at: twitter_user.updated_at - 1.day)
      twitter_user2 = create(:twitter_user, uid: twitter_user.uid)

      twitter_user.friend_ids = twitter_user2.friend_ids
      twitter_user2.friends[0].destroy
    end
    it 'creates unfriendships' do
      removing_size = twitter_user.calc_removing.size
      expect(removing_size).to eq(1)
      expect { Unfriendship.import_from!(twitter_user) }.to change { Unfriendship.all.size }.by(removing_size)

      twitter_user.reload
      expect(twitter_user.unfriends.map(&:uid)).to eq(twitter_user.calc_removing.map(&:uid).map(&:to_i))
    end
  end
end
