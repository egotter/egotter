require 'rails_helper'

RSpec.describe TwitterDB::Friendship, type: :model do
  describe '.import_from!' do
    let(:user_uid) { 1 }
    let(:user_uid2) { 2 }
    let(:friend_uids) { [1, 2, 3] }
    let(:friend_uids2) { [3, 4, 5, 6] }

    before do
      [user_uid, user_uid2, friend_uids, friend_uids2].flatten.uniq.each { |uid| create(:twitter_db_user, uid: uid) }
      friend_uids.each.with_index { |uid, i| TwitterDB::Friendship.create(user_uid: user_uid2, friend_uid: uid, sequence: i) }
    end

    it 'creates records' do
      expect { TwitterDB::Friendship.import_from!(user_uid, friend_uids) }.to change { TwitterDB::Friendship.where(user_uid: user_uid).size }.by(friend_uids.size)
      expect(TwitterDB::Friendship.where(user_uid: user_uid).pluck(:friend_uid)).to match_array(friend_uids)
    end

    it 'deletes records' do
      TwitterDB::Friendship.import_from!(user_uid, friend_uids)
      expect { TwitterDB::Friendship.import_from!(user_uid, friend_uids2) }.to change { TwitterDB::Friendship.where(user_uid: user_uid).size }.by(friend_uids2.size - friend_uids.size)
      expect(TwitterDB::Friendship.where(user_uid: user_uid).pluck(:friend_uid)).to match_array(friend_uids2)
    end
  end
end
