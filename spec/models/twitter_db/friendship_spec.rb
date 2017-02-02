require 'rails_helper'

RSpec.describe TwitterDB::Friendship, type: :model do
  describe '.import_from!' do
    let(:user_uid) { 1 }
    let(:friend_uids) { [1, 2, 3] }
    let(:friend_uids2) { [3, 4, 5] }

    before do
      [user_uid, friend_uids, friend_uids2].flatten.uniq.each { |uid| create(:twitter_db_user, uid: uid) }
    end

    it 'creates records' do
      expect { TwitterDB::Friendship.import_from!(user_uid, friend_uids) }.to change { TwitterDB::Friendship.all.size }.by(friend_uids.size)
      expect(TwitterDB::Friendship.pluck(:friend_uid)).to match_array(friend_uids)
    end

    it 'deletes records' do
      TwitterDB::Friendship.import_from!(user_uid, friend_uids)
      expect { TwitterDB::Friendship.import_from!(user_uid, friend_uids2) }.to change { TwitterDB::Friendship.all.size }.by(friend_uids.size - friend_uids.size)
      expect(TwitterDB::Friendship.pluck(:friend_uid)).to match_array(friend_uids2)
    end
  end
end
