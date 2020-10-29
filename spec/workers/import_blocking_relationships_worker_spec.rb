require 'rails_helper'

RSpec.describe ImportBlockingRelationshipsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    subject { worker.perform(user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive_message_chain(:api_client, :twitter).and_return('client')
    end

    it do
      expect(worker).to receive(:fetch_blocked_uids).with('client').and_return('ids')
      expect(BlockingRelationship).to receive(:import_from).with(user.uid, 'ids')
      subject
    end
  end
end
