require 'rails_helper'

RSpec.describe CreateBlockReportWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:client) { double('client') }
    subject { worker.perform(user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive(:api_client).and_return(client)
      create(:blocking_relationship, from_uid: 1, to_uid: user.uid)
    end

    it do
      expect(client).to receive(:users).with([1]).and_return([{id: 1, screen_name: 'name'}])
      expect(BlockReport).to receive(:you_are_blocked).with(user.id, [{uid: 1, screen_name: 'name'}])
      subject
    end
  end
end
