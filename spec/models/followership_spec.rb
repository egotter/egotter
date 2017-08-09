require 'rails_helper'

RSpec.describe Followership, type: :model do
  describe '.import_from!' do
    let(:from_id) { 1 }
    let(:follower_uids) { [1, 2, 3] }
    let(:follower_uids2) { [3, 4, 5, 6] }

    before do
      follower_uids.each.with_index { |uid, i| Followership.create(from_id: 2, follower_uid: uid, sequence: i) }
    end

    it 'creates records' do
      expect { Followership.import_from!(from_id, follower_uids) }.to change { Followership.where(from_id: from_id).size }.by(follower_uids.size)
      expect(Followership.where(from_id: from_id).pluck(:follower_uid)).to match_array(follower_uids)
    end

    it 'deletes records' do
      Followership.import_from!(from_id, follower_uids)
      expect { Followership.import_from!(from_id, follower_uids2) }.to change { Followership.all.size }.by(follower_uids2.size - follower_uids.size)
      expect(Followership.where(from_id: from_id).pluck(:follower_uid)).to match_array(follower_uids2)
    end
  end
end
