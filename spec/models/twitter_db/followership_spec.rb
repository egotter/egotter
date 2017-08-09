require 'rails_helper'

RSpec.describe TwitterDB::Followership, type: :model do
  describe '.import_from!' do
    let(:user_uid) { 1 }
    let(:user_uid2) { 2 }
    let(:follower_uids) { [1, 2, 3] }
    let(:follower_uids2) { [3, 4, 5, 6] }

    before do
      [user_uid, user_uid2, follower_uids, follower_uids2].flatten.uniq.each { |uid| create(:twitter_db_user, uid: uid) }
      follower_uids.each.with_index { |uid, i| TwitterDB::Followership.create(user_uid: user_uid2, follower_uid: uid, sequence: i) }
    end

    it 'creates records' do
      expect { TwitterDB::Followership.import_from!(user_uid, follower_uids) }.to change { TwitterDB::Followership.where(user_uid: user_uid).size }.by(follower_uids.size)
      expect(TwitterDB::Followership.where(user_uid: user_uid).pluck(:follower_uid)).to match_array(follower_uids)
    end

    it 'deletes records' do
      TwitterDB::Followership.import_from!(user_uid, follower_uids)
      expect { TwitterDB::Followership.import_from!(user_uid, follower_uids2) }.to change { TwitterDB::Followership.where(user_uid: user_uid).size }.by(follower_uids2.size - follower_uids.size)
      expect(TwitterDB::Followership.where(user_uid: user_uid).pluck(:follower_uid)).to match_array(follower_uids2)
    end
  end
end
