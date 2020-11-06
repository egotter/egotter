require 'rails_helper'

RSpec.describe UpdateLockedWorker do
  let(:worker) { described_class.new }

  describe '#unique_key' do
    it { expect(worker.unique_key(1)).to eq(1) }
  end

  describe '#unique_in' do
    it { expect(worker.unique_in).to eq(1.minute) }
  end

  describe '#expire_in' do
    it { expect(worker.expire_in).to eq(1.minute) }
  end

  describe '#perform' do
    let(:user) { create(:user) }
    subject { worker.perform(user.id) }
    before { allow(User).to receive(:find).with(user.id).and_return(user) }
    it do
      expect(user).to receive_message_chain(:api_client, :users)
      subject
    end
  end
end
