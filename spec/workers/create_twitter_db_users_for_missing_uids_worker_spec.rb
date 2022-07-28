require 'rails_helper'

RSpec.describe CreateTwitterDBUsersForMissingUidsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:data) { 'data' }
    let(:uids) { [1, 2, 3] }
    subject { worker.perform(data, 1) }
    it do
      expect(worker).to receive(:decompress).with(data).and_return(uids)
      expect(worker).to receive(:filter_missing_uids).with(uids).and_return([1, 2])
      expect(CreateTwitterDBUserWorker).to receive(:push_bulk).with([1, 2], user_id: 1, enqueued_by: described_class)
      subject
    end
  end

  describe '.push_bulk' do
    let(:user_id) { 1 }
    subject { described_class.push_bulk(uids, user_id) }

    context '100 < uids.size' do
      let(:uids1) { (1..100).to_a }
      let(:encoded_uids1) { 'encoded_uids1' }
      let(:uids2) { (101..110).to_a }
      let(:encoded_uids2) { 'encoded_uids2' }
      let(:uids) { (1..110).to_a }
      before do
        allow(described_class).to receive(:compress).with(uids1).and_return(encoded_uids1)
        allow(described_class).to receive(:compress).with(uids2).and_return(encoded_uids2)
      end
      it do
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), encoded_uids1, user_id, {})
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), encoded_uids2, user_id, {})
        subject
      end
    end

    context 'uids.size < 100' do
      let(:uids1) { (1..50).to_a }
      let(:encoded_uids1) { 'encoded_uids1' }
      let(:uids) { (1..50).to_a }
      before do
        allow(described_class).to receive(:compress).with(uids1).and_return(encoded_uids1)
      end
      it do
        expect(described_class).to receive(:perform_in).with(instance_of(Integer), encoded_uids1, user_id, {})
        subject
      end
    end
  end

  describe '#decompress' do
    let(:data) { [1, 2, 3] }
    subject { worker.send(:decompress, data) }
    it { is_expected.to eq([1, 2, 3]) }

    context 'data is compressed' do
      let(:data) { Base64.encode64(Zlib::Deflate.deflate([1, 2, 3].to_json)) }
      it { is_expected.to eq([1, 2, 3]) }
    end
  end

  describe '#filter_missing_uids' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:filter_missing_uids, uids) }

    context 'all uids are persisted to TwitterDB::QueuedUser' do
      before { uids.each { |uid| create(:twitter_db_queued_user, uid: uid) } }
      it do
        expect(TwitterDB::QueuedUser).to receive(:where).with(anything).and_call_original
        expect(TwitterDB::User).not_to receive(:where)
        is_expected.to eq([])
      end
    end

    context 'all uids are persisted to TwitterDB::QueuedUser and TwitterDB::User' do
      before do
        create(:twitter_db_queued_user, uid: uids[0])
        create(:twitter_db_user, uid: uids[1])
        create(:twitter_db_user, uid: uids[2])
      end
      it do
        expect(TwitterDB::QueuedUser).to receive(:where).with(anything).and_call_original.twice
        expect(TwitterDB::User).to receive(:where).with(anything).and_call_original
        is_expected.to eq([])
      end
    end

    context 'some uids are persisted to TwitterDB::QueuedUser and TwitterDB::User' do
      before do
        create(:twitter_db_queued_user, uid: uids[0])
        create(:twitter_db_user, uid: uids[1])
      end
      it do
        expect(TwitterDB::QueuedUser).to receive(:where).with(anything).and_call_original.twice
        expect(TwitterDB::User).to receive(:where).with(anything).and_call_original.twice
        is_expected.to eq([3])
      end
    end
  end
end
