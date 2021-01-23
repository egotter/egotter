require 'rails_helper'

RSpec.describe UpdateEgotterFollowersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    it do
      expect(worker).to receive(:collect_follower_uids).and_return('uids1')
      expect(worker).to receive(:import_follower_uids).with('uids1')
      expect(worker).to receive(:filter_missing_uids).with('uids1').and_return('uids2')
      expect(worker).to receive(:delete_missing_uids).with('uids2')
      subject
    end
  end

  describe '#collect_follower_uids' do
    let(:ids) { [1, 2, 3] }
    let(:response) { double('Response', attrs: {ids: ids, next_cursor: 0}) }
    let(:client) { double('Client') }
    subject { worker.send(:collect_follower_uids) }
    before do
      allow(Bot).to receive_message_chain(:api_client, :twitter).and_return(client)
      allow(client).to receive(:follower_ids).with(any_args).and_return(response)
    end
    it { is_expected.to eq(ids) }
  end

  describe '#import_follower_uids' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:import_follower_uids, uids) }
    before { EgotterFollower.create!(uid: 1, screen_name: 'sn') }
    it { expect { subject }.to change { EgotterFollower.all.size }.by(2) }
  end

  describe '#filter_missing_uids' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:filter_missing_uids, uids) }
    before { EgotterFollower.create!(uid: 1, screen_name: 'sn') }
    it { is_expected.to eq([2, 3]) }
  end

  describe '#delete_missing_uids' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:delete_missing_uids, uids) }
    before do
      EgotterFollower.create!(uid: 3, screen_name: 'sn')
      EgotterFollower.create!(uid: 4, screen_name: 'sn')
    end
    it { expect { subject }.to change { EgotterFollower.all.size }.by(-1) }
  end
end
