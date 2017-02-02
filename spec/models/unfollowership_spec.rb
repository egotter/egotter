require 'rails_helper'

RSpec.describe Unfollowership, type: :model do
  describe '.import_from!' do
    let(:from_uid) { 1 }
    let(:follower_uids) { [1, 2, 3] }
    let(:follower_uids2) { [3, 4, 5] }

    it 'creates records' do
      expect { Unfollowership.import_from!(from_uid, follower_uids) }.to change { Unfollowership.all.size }.by(follower_uids.size)
      expect(Unfollowership.pluck(:follower_uid)).to match_array(follower_uids)
    end

    it 'deletes records' do
      Unfollowership.import_from!(from_uid, follower_uids)
      expect { Unfollowership.import_from!(from_uid, follower_uids2) }.to change { Unfollowership.all.size }.by(follower_uids.size - follower_uids.size)
      expect(Unfollowership.pluck(:follower_uid)).to match_array(follower_uids2)
    end
  end
end
