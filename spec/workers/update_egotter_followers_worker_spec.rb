require 'rails_helper'

RSpec.describe UpdateEgotterFollowersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    it do
      expect(EgotterFollower).to receive(:collect_uids).and_return('uids1')
      expect(EgotterFollower).to receive(:import_uids).with('uids1')
      expect(EgotterFollower).to receive(:filter_unnecessary_uids).with('uids1').and_return('uids2')
      expect(EgotterFollower).to receive(:delete_uids).with('uids2')
      subject
    end
  end
end
