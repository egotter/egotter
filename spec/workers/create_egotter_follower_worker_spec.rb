require 'rails_helper'

RSpec.describe CreateEgotterFollowerWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.id) }
    it do
      expect(EgotterFollower).to receive(:import_uids).with([user.uid])
      subject
    end
  end

  describe '#unique_key' do
    subject { described_class.new.unique_key(1) }
    it { is_expected.to eq(1) }
  end

  describe '#unique_in' do
    subject { described_class.new.unique_in }
    it { is_expected.to eq(1.minute) }
  end
end
