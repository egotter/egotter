require 'rails_helper'

RSpec.describe ImportBlockingRelationshipsWorker do
  let(:user) { create(:user) }
  let(:client) { double('client') }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user2) { create(:user) }
    let(:blocked_ids) { [user2.uid] }
    subject { worker.perform(user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive_message_chain(:api_client, :twitter).and_return(client)
    end

    it do
      expect(worker).to receive(:fetch_blocked_uids).with(client).and_return(blocked_ids)
      expect(BlockingRelationship).to receive(:import_from).with(user.uid, blocked_ids)
      expect(CreateBlockReportWorker).to receive(:perform_in).with(anything, user2.id)
      subject
    end
  end

  describe '#fetch_blocked_uids' do
    let(:response) { double('response', attrs: {ids: [1, 2, 2, 3], next_cursor: 0}) }
    subject { worker.send(:fetch_blocked_uids, client) }
    before { allow(client).to receive(:blocked_ids).with(anything).and_return(response) }
    it { is_expected.to eq([1, 2, 3]) }
  end
end
