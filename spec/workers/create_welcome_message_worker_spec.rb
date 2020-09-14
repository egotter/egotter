require 'rails_helper'

RSpec.describe CreateWelcomeMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    subject { worker.perform(user.id, {}) }

    it do
      expect(WelcomeMessage).to receive_message_chain(:welcome, :deliver!).with(user.id).with(no_args)
      subject
    end

    context 'An error occurs when sending a welcome message' do
      before do
        allow(WelcomeMessage).to receive_message_chain(:welcome, :deliver!).
            with(user.id).with(no_args).and_raise('Error')
      end
      it do
        expect(SendMessageToSlackWorker).to receive(:perform_async).with(:welcome_messages, instance_of(String), user.id)
        subject
      end
    end
  end
end
