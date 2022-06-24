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
      expect(BlockingRelationship).to receive(:update_all_blocks).with(user).and_return(blocked_ids)
      expect(CreateBlockReportWorker).to receive(:perform_in).with(anything, user2.id)
      subject
    end
  end
end
