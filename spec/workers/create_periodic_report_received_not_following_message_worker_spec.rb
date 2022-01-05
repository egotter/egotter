require 'rails_helper'

RSpec.describe CreatePeriodicReportReceivedNotFollowingMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before { user.create_credential_token!(token: 't', secret: 's') }

  describe '#perform' do
    subject { worker.perform(user.uid) }
    before { allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(false) }
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message).with(user.uid, instance_of(String))
      subject
    end
  end
end
