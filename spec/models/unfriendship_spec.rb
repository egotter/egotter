require 'rails_helper'

RSpec.describe Unfriendship, type: :model do
  describe '.import_from!' do
    let(:from_uid) { 1 }
    let(:friend_uids) { [1, 2, 3] }
    let(:friend_uids2) { [3, 4, 5] }

    it 'creates records' do
      expect { Unfriendship.import_from!(from_uid, friend_uids) }.to change { Unfriendship.all.size }.by(friend_uids.size)
      expect(Unfriendship.pluck(:friend_uid)).to match_array(friend_uids)
    end

    it 'deletes records' do
      Unfriendship.import_from!(from_uid, friend_uids)
      expect { Unfriendship.import_from!(from_uid, friend_uids2) }.to change { Unfriendship.all.size }.by(friend_uids.size - friend_uids.size)
      expect(Unfriendship.pluck(:friend_uid)).to match_array(friend_uids2)
    end
  end
end
