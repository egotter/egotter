require 'rails_helper'

RSpec.describe CreateTwitterDBUsersForMissingUidsWorker do
  let(:worker) { described_class.new }

  describe '.perform_async' do
    class TestCreateTwitterDBUsersForMissingUidsWorker < CreateTwitterDBUsersForMissingUidsWorker
      def perform(uids, user_id, options)
        self.class.do_perform(uids, user_id, options)
      end

      class << self
        def do_perform(*) end
      end
    end

    let(:user_id) { 1 }
    let(:worker_wrapper) do
      TestCreateTwitterDBUsersForMissingUidsWorker
    end

    context '100 < uids.size' do
      let(:uids1) { (1..100).to_a }
      let(:encoded_uids1) { Base64.encode64(Zlib::Deflate.deflate(uids1.to_json)) }
      let(:uids2) { (101..110).to_a }
      let(:uids) { (1..110).to_a }
      it do
        expect(worker_wrapper).to receive(:do_perform).with(encoded_uids1, user_id, {})
        expect(worker_wrapper).to receive(:do_perform).with(uids2, user_id, {})
        worker_wrapper.perform_async(uids, user_id)
        worker_wrapper.drain
      end
    end

    context '10 < uids.size < 100' do
      let(:uids) { (1..50).to_a }
      let(:encoded_uids) { Base64.encode64(Zlib::Deflate.deflate(uids.to_json)) }
      it do
        expect(worker_wrapper).to receive(:do_perform).with(encoded_uids, user_id, {})
        worker_wrapper.perform_async(uids, user_id)
        worker_wrapper.drain
      end
    end

    context 'uids.size < 10' do
      let(:uids) { (1..5).to_a }
      it do
        expect(worker_wrapper).to receive(:do_perform).with(uids, user_id, {})
        worker_wrapper.perform_async(uids, user_id)
        worker_wrapper.drain
      end
    end
  end

  describe '#fetch_missing_uids' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:fetch_missing_uids, uids) }
    before { create(:twitter_db_user, uid: 2) }
    it { is_expected.to eq([1, 3]) }
  end
end
