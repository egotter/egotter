require 'rails_helper'

RSpec.describe UpdatePermissionLevelWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    subject { worker.perform(user.id) }
    before do
      allow(user).to receive_message_chain(:api_client, :permission_level).and_return('level')
      allow(user).to receive_message_chain(:notification_setting, :permission_level).and_return('invalid')
    end
    it do
      allow(user).to receive_message_chain(:notification_setting, :update).with(permission_level: 'level')
      subject
    end
  end
end
