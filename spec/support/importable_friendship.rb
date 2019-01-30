shared_examples_for 'Importable friendship' do
  describe '.import_from!' do
    let(:from_uid) { 1 }
    let(:friend_uids) { [1, 2, 3] }
    let(:friend_uids2) { [3, 4, 5, 6] }

    before do
      friend_uids.each.with_index { |uid, i| klass.create(from_uid: 2, friend_uid: uid, sequence: i) }
    end

    it 'creates records' do
      expect { klass.import_from!(from_uid, friend_uids) }.to change { klass.where(from_uid: from_uid).size }.by(friend_uids.size)
      expect(klass.where(from_uid: from_uid).pluck(:friend_uid)).to match_array(friend_uids)
    end

    it 'deletes records' do
      klass.import_from!(from_uid, friend_uids)
      expect { klass.import_from!(from_uid, friend_uids2) }.to change { klass.where(from_uid: from_uid).size }.by(friend_uids2.size - friend_uids.size)
      expect(klass.where(from_uid: from_uid).pluck(:friend_uid)).to match_array(friend_uids2)
    end
  end
end
