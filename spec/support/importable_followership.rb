shared_examples_for 'Importable followership' do
  describe '.import_from!' do
    let(:from_uid) { 1 }
    let(:follower_uids) { [1, 2, 3] }
    let(:follower_uids2) { [3, 4, 5, 6] }

    before do
      follower_uids.each.with_index { |uid, i| klass.create(from_uid: 2, follower_uid: uid, sequence: i) }
    end

    it 'creates records' do
      expect { klass.import_from!(from_uid, follower_uids) }.to change { klass.where(from_uid: from_uid).size }.by(follower_uids.size)
      expect(klass.where(from_uid: from_uid).pluck(:follower_uid)).to match_array(follower_uids)
    end

    it 'deletes records' do
      klass.import_from!(from_uid, follower_uids)
      expect { klass.import_from!(from_uid, follower_uids2) }.to change { klass.where(from_uid: from_uid).size }.by(follower_uids2.size - follower_uids.size)
      expect(klass.where(from_uid: from_uid).pluck(:follower_uid)).to match_array(follower_uids2)
    end
  end
end
