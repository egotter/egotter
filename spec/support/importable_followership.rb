shared_examples_for 'Importable followership' do
  describe '.import_from!' do
    let(:from_uid) { 1 }
    let(:follower_uids) { [1, 2, 3] }
    let(:follower_uids2) { [3, 4, 5, 6] }

    before do
      follower_uids.each.with_index do |uid, i|
        described_class.create(from_uid: 2, follower_uid: uid, sequence: i)
      end
    end

    it 'creates records' do
      expect { described_class.import_from!(from_uid, follower_uids) }.to change {
        described_class.where(from_uid: from_uid).size
      }.by(follower_uids.size)

      expect(described_class.where(from_uid: from_uid).pluck(:follower_uid)).to match_array(follower_uids)
    end

    context 'Records already exist' do
      before { described_class.import_from!(from_uid, follower_uids) }

      it 'deletes records' do
        expect { described_class.import_from!(from_uid, follower_uids2) }.to change {
          described_class.where(from_uid: from_uid).size
        }.by(follower_uids2.size - follower_uids.size)

        expect(described_class.where(from_uid: from_uid).pluck(:follower_uid)).to match_array(follower_uids2)
      end
    end
  end
end
