require 'rails_helper'

RSpec.describe CreateEgotterFollowerWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#unique_key' do
    subject { described_class.new.unique_key(1) }
    it { is_expected.to eq(1) }
  end

  describe '#unique_in' do
    subject { described_class.new.unique_in }
    it { is_expected.to eq(1.minute) }
  end

  describe '#perform' do
    subject { worker.perform(user.id) }
    before { allow(User).to receive(:find).with(user.id).and_return(user) }
    it do
      expect(worker).to receive(:create_record).with(user)
      subject
    end
  end

  describe '#create_record' do
    subject { worker.create_record(user) }
    it { expect { subject }.to change { EgotterFollower.all.size }.by(1) }
  end
end
