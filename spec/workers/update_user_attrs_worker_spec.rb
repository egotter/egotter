require 'rails_helper'

RSpec.describe UpdateUserAttrsWorker do
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
    let(:api_user) { double('api_user', screen_name: 'new_name') }
    subject { worker.perform(user.id) }
    before { allow(User).to receive(:find).with(user.id).and_return(user) }
    it do
      expect(user).to receive_message_chain(:api_client, :twitter, :verify_credentials).and_return(api_user)
      subject
      expect(user.reload.screen_name).to eq(api_user.screen_name)
    end
  end
end
