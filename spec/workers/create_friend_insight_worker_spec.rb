require 'rails_helper'

RSpec.describe CreateFriendInsightWorker do
  let(:worker) { described_class.new }

  describe '#unique_key' do
    it { expect(worker.unique_key(1)).to eq(1) }
  end

  describe '#unique_in' do
    it { expect(worker.unique_in).to eq(1.minute) }
  end

  describe '#expire_in' do
    it { expect(worker.expire_in).to eq(10.minutes) }
  end

  describe '#perform' do
    subject { worker.perform(1) }
    it do
      expect(FriendInsight).to receive_message_chain(:builder, :build, :save!).
          with(1).with(no_args).with(no_args)
      subject
    end
  end
end
