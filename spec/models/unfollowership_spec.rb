require 'rails_helper'

RSpec.describe Unfollowership, type: :model do
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

      twitter_user.follower_ids = twitter_user2.follower_ids
      twitter_user2.followers[0].destroy
    end
    it 'creates unfollowerships' do
      removed_size = twitter_user.calc_removed.size
      expect(removed_size).to eq(1)
      expect { Unfollowership.import_from!(twitter_user) }.to change { Unfollowership.all.size }.by(removed_size)

      twitter_user.reload
      expect(twitter_user.unfollowers.map(&:id)).to eq(twitter_user.calc_removed.map(&:id))
    end
  end
end
