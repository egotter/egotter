require 'rails_helper'

RSpec.describe ImportMutingRelationshipsWorker do
  let(:user) { create(:user) }
  let(:client) { double('client') }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user2) { create(:user) }
    let(:muted_ids) { [user2.uid] }
    subject { worker.perform(user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive_message_chain(:api_client, :twitter).and_return(client)
    end

    it do
      expect(MutingRelationship).to receive(:collect_uids).with(user.id).and_return(muted_ids)
      expect(MutingRelationship).to receive(:import_from).with(user.uid, muted_ids)
      # expect(CreateBlockReportWorker).to receive(:perform_in).with(anything, user2.id)
      subject
    end
  end
end
