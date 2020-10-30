require 'rails_helper'

RSpec.describe ImportBlockingRelationshipsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:client) { double('client') }
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
      expect(CreateBlockReportWorker).to receive(:perform_async).with(user2.id)
      subject
    end
  end
end
