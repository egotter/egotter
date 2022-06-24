require 'rails_helper'

RSpec.describe UpdateEgotterFollowersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    it do
      expect(EgotterFollower).to receive(:update_all_uids)
      subject
    end
  end
end
