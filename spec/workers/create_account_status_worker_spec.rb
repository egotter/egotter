require 'rails_helper'

RSpec.describe CreateAccountStatusWorker do
  let(:worker) { described_class.new }

  describe '#unique_key' do
    it do
      expect(worker.unique_key('name', user_id: 1)).to eq('1-name')
      expect(worker.unique_key('name', 'user_id' => 1)).to eq('1-name')
    end
  end

  describe '#perform' do
    let(:user) { create(:user) }
    let(:screen_name) { 'name' }
    let(:cache) { instance_double(AccountStatus::Cache) }
    subject { worker.perform(screen_name, 'user_id' => user.id) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive(:api_client).and_return('client')
      allow(AccountStatus::Cache).to receive(:new).and_return(cache)
    end

    it do
      expect(worker).to receive(:detect_status).with('client', user, screen_name).and_return([1, 2, 3])
      expect(cache).to receive(:write).with(screen_name, 1, 2, 3)
      expect(CreateHighPriorityTwitterDBUserWorker).to receive(:perform_async).with([2], user_id: user.id, enqueued_by: worker.class)
      subject
    end
  end
end
