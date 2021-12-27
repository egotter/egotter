require 'rails_helper'

RSpec.describe CreateWelcomeMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    let(:options) { {} }
    subject { worker.perform(user.id, options) }

    it do
      expect(worker).to receive(:send_direct_message).with(user, options)
      subject
    end

    context 'sending DM is rate-limited' do
      before { allow(PeriodicReport).to receive(:send_report_limited?).with(user.uid).and_return(true) }
      it do
        expect(worker).to receive(:retry_current_report).with(user.id, options)
        expect(worker).not_to receive(:send_direct_message)
        subject
      end
    end
  end

  describe '#send_direct_message' do
    let(:options) { {} }
    subject { worker.send_direct_message(user, options) }

    it do
      expect(WelcomeMessage).to receive_message_chain(:welcome, :deliver!).with(user.id).with(no_args)
      subject
    end

    context 'an exception is raised' do
      before { allow(WelcomeMessage).to receive(:welcome).with(user.id).and_raise('anything') }

      context 'the exception is Twitter::Error::EnhanceYourCalm' do
        before { allow(DirectMessageStatus).to receive(:enhance_your_calm?).with(anything).and_return(true) }
        it do
          expect(worker).to receive(:retry_current_report).with(user.id, options, exception: instance_of(RuntimeError))
          expect { subject }.not_to raise_error
        end
      end

      context 'the exception is unknown' do
        it do
          expect(SendMessageToSlackWorker).to receive(:perform_async).with(:messages_welcome, instance_of(String))
          subject
        end
      end
    end
  end
end
