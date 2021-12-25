require 'rails_helper'

RSpec.describe UpdateEgotterFollowersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:uids) { [1, 2, 3, 5, 6] }
    let(:persisted_uids) { [1, 2, 3, 4, 5] }
    let(:importable_uids) { [6] }
    let(:deletable_uids) { [4] }
    subject { worker.perform }
    before { persisted_uids.each { |uid| create(:egotter_follower, uid: uid) } }
    it do
      expect(EgotterFollower).to receive(:collect_uids).and_return(uids)
      expect(EgotterFollower).to receive(:filter_necessary_uids).with(uids).and_call_original
      expect(EgotterFollower).to receive(:import_uids).with(importable_uids).and_call_original
      expect(EgotterFollower).to receive(:filter_unnecessary_uids).with(uids).and_call_original
      expect(EgotterFollower).to receive(:delete_uids).with(deletable_uids).and_call_original
      subject
      expect(EgotterFollower.pluck(:uid)).to eq(uids)
    end
  end
end
