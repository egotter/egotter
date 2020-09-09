require 'rails_helper'

RSpec.describe UpdateEgotterFriendshipWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    let(:client) { 'client' }
    subject { worker.perform(user.id, {}) }
    before { allow(user).to receive_message_chain(:api_client, :twitter).and_return(client) }
    it do
      expect(worker).to receive(:verify_credentials).with(client)
      expect(worker).to receive(:update_friendship).with(client, user)
      subject
    end
  end
end
