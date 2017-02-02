require 'rails_helper'

RSpec.describe Friendship, type: :model do
  describe '.import_from!' do
    let(:from_id) { 1 }
    let(:friend_uids) { [1, 2, 3] }
    let(:friend_uids2) { [3, 4, 5] }

    it 'creates records' do
      expect { Friendship.import_from!(from_id, friend_uids) }.to change { Friendship.all.size }.by(friend_uids.size)
      expect(Friendship.pluck(:friend_uid)).to match_array(friend_uids)
    end

    it 'deletes records' do
      Friendship.import_from!(from_id, friend_uids)
      expect { Friendship.import_from!(from_id, friend_uids2) }.to change { Friendship.all.size }.by(friend_uids.size - friend_uids.size)
      expect(Friendship.pluck(:friend_uid)).to match_array(friend_uids2)
    end
  end
end
