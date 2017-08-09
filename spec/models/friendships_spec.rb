require 'rails_helper'

RSpec.describe Friendships, type: :model do
  describe '.import' do
    let(:from_id) { 1 }
    let(:friend_uids)    { [1, 2, 3] }
    let(:friend_uids2)   { [3, 4, 5, 6] }
    let(:follower_uids)  { [6, 7, 8] }
    let(:follower_uids2) { [7, 8, 9, 10] }

    let(:duplicate_friend_uids) { friend_uids2 - friend_uids }
    let(:duplicate_follower_uids) { follower_uids2 - follower_uids }

    context 'Friendship' do
      before do
        friend_uids.each.with_index { |uid, i| Friendship.create(from_id: 2, friend_uid: uid, sequence: i) }
      end

      it 'imports records' do
        expect { Friendships.import(from_id, friend_uids, follower_uids) }.to change { Friendship.where(from_id: from_id).size }.by(friend_uids.size)
        expect(Friendship.where(from_id: from_id).pluck(:friend_uid)).to match_array(friend_uids)
      end

      it 'deletes records' do
        Friendships.import(from_id, friend_uids, follower_uids)
        expect { Friendships.import(from_id, friend_uids2, follower_uids2) }.to change { Friendship.where(from_id: from_id).size }.by(friend_uids2.size - friend_uids.size)
        expect(Friendship.where(from_id: from_id).pluck(:friend_uid)).to match_array(friend_uids2)
      end
    end

    context 'Followership' do
      before do
        follower_uids.each.with_index { |uid, i| Followership.create(from_id: 2, follower_uid: uid, sequence: i) }
      end

      it 'imports records' do
        expect { Friendships.import(from_id, friend_uids, follower_uids) }.to change { Followership.where(from_id: from_id).size }.by(follower_uids.size)
        expect(Followership.where(from_id: from_id).pluck(:follower_uid)).to match_array(follower_uids)
      end

      it 'deletes records' do
        Friendships.import(from_id, friend_uids, follower_uids)
        expect { Friendships.import(from_id, friend_uids2, follower_uids2) }.to change { Followership.where(from_id: from_id).size }.by(follower_uids2.size - follower_uids.size)
        expect(Followership.where(from_id: from_id).pluck(:follower_uid)).to match_array(follower_uids2)
      end
    end
  end
end
