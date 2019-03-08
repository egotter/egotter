shared_examples_for 'Importable friendship' do
  describe '.import_from!' do
    let(:from_uid) { 1 }
    let(:friend_uids) { [1, 2, 3] }
    let(:friend_uids2) { [3, 4, 5, 6] }

    before do
      friend_uids.each.with_index do |uid, i|
        described_class.create(from_uid: 2, friend_uid: uid, sequence: i)
      end
    end

    it 'creates records' do
      expect { described_class.import_from!(from_uid, friend_uids) }.to change {
        described_class.where(from_uid: from_uid).size
      }.by(friend_uids.size)

      expect(described_class.where(from_uid: from_uid).pluck(:friend_uid)).to match_array(friend_uids)
    end

    context 'Records already exist' do
      before { described_class.import_from!(from_uid, friend_uids) }

      it 'deletes records' do
        expect { described_class.import_from!(from_uid, friend_uids2) }.to change {
          described_class.where(from_uid: from_uid).size
        }.by(friend_uids2.size - friend_uids.size)

        expect(described_class.where(from_uid: from_uid).pluck(:friend_uid)).to match_array(friend_uids2)
      end
    end
  end
end
