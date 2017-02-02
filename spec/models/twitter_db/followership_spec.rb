require 'rails_helper'

RSpec.describe TwitterDB::Followership, type: :model do
  describe '.import_from!' do
    let(:user_uid) { 1 }
    let(:follower_uids) { [1, 2, 3] }
    let(:follower_uids2) { [3, 4, 5] }

    before do
      [user_uid, follower_uids, follower_uids2].flatten.uniq.each { |uid| create(:twitter_db_user, uid: uid) }
    end

    it 'creates records' do
      expect { TwitterDB::Followership.import_from!(user_uid, follower_uids) }.to change { TwitterDB::Followership.all.size }.by(follower_uids.size)
      expect(TwitterDB::Followership.pluck(:follower_uid)).to match_array(follower_uids)
    end

    it 'deletes records' do
      TwitterDB::Followership.import_from!(user_uid, follower_uids)
      expect { TwitterDB::Followership.import_from!(user_uid, follower_uids2) }.to change { TwitterDB::Followership.all.size }.by(follower_uids.size - follower_uids.size)
      expect(TwitterDB::Followership.pluck(:follower_uid)).to match_array(follower_uids2)
    end
  end
end
