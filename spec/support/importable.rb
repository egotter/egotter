shared_examples_for 'Importable by import_by!' do
  describe '.import_by!' do
    let(:twitter_user) { create(:twitter_user) }
    let(:uids) { [1, 2, 3] }

    it 'calls specified method' do
      expect(twitter_user).to receive(method_name).and_return(uids)
      described_class.import_by!(twitter_user: twitter_user)
    end

    it 'calls .import_from!' do
      allow(twitter_user).to receive(method_name).and_return(uids)
      expect(described_class).to receive(:import_from!).with(twitter_user.uid, uids)
      described_class.import_by!(twitter_user: twitter_user)
    end

    it 'returns uids' do
      allow(twitter_user).to receive(method_name).and_return(uids)
      allow(described_class).to receive(:import_from!).with(twitter_user.uid, uids)
      expect(described_class.import_by!(twitter_user: twitter_user)).to match_array(uids)
    end
  end

  describe '.import_by' do
    let(:twitter_user) { create(:twitter_user) }
    let(:uids) { [1, 2, 3] }

    it 'calls .import_by!' do
      expect(described_class).to receive(:import_by!).with(hash_including(twitter_user: twitter_user)).and_call_original
      described_class.import_by(twitter_user: twitter_user)
    end

    context '.import_by! raises an error' do
      before { expect(described_class).to receive(:import_by!).with(anything).and_raise }

      it "doesn't raise an error" do
        expect(described_class.import_by(twitter_user: twitter_user)).to be_empty
      end
    end
  end
end
