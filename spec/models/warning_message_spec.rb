require 'rails_helper'

RSpec.describe WarningMessage do
  let(:user) { create(:user) }

  describe '#deliver!' do
    let(:client) { double('client') }
    let(:dm) { double('dm', id: 1, truncated_message: 'text') }
    let(:instance) { described_class.new(user_id: user.id, message: 'text', token: 'token') }
    subject { instance.deliver! }

    before do
      allow(User).to receive_message_chain(:egotter, :api_client).with(no_args).with(no_args).and_return(client)
    end

    it do
      expect(client).to receive(:create_direct_message_event).with(user.uid, 'text').and_return(dm)
      expect(instance).to receive(:update!).with(message_id: dm.id, message: dm.truncated_message)
      expect(subject).to eq(dm)
    end
  end
end
