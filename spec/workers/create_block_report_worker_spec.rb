require 'rails_helper'

RSpec.describe CreateBlockReportWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:client) { double('client') }
    subject { worker.perform(user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      create(:blocking_relationship, from_uid: 1, to_uid: user.uid)
    end

    it do
      expect(BlockReport).to receive(:you_are_blocked).with(user.id)
      subject
    end
  end
end
