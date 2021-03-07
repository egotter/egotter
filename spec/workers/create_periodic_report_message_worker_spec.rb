require 'rails_helper'

RSpec.describe CreatePeriodicReportMessageWorker do
  let(:user) { create(:user, with_credential_token: true) }
  let(:worker) { described_class.new }

  describe '#unique_key' do
    let(:user_id) { user.id }
    let(:options) { {} }
    subject { worker.unique_key(user_id, options) }

    it { is_expected.to start_with(user.id.to_s) }

    context 'user_id is nil' do
      let(:user_id) { nil }
      let(:options) { {uid: user.uid} }
      it { is_expected.to start_with("uid-#{user.uid}") }
    end
  end

  describe '#perform' do
    let(:user_id) { user.id }
    let(:options) { {} }
    subject { worker.perform(user_id, options) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
    end

    it do
      expect(worker).to receive(:send_push_message).with(user, options)
      expect(worker).to receive(:send_direct_message).with(user, options)
      subject
    end

    context 'sending DM is rate-limited' do
      before { allow(PeriodicReport).to receive(:send_report_limited?).with(user.uid).and_return(true) }
      it do
        expect(worker).to receive(:retry_current_report).with(user.id, options)
        expect(worker).not_to receive(:send_push_message)
        expect(worker).not_to receive(:send_direct_message)
        subject
      end
    end
  end

  describe '#send_push_message' do
    let(:options) { {request_id: 1} }
    subject { worker.send_push_message(user, options) }
    before { allow(user).to receive_message_chain(:credential_token, :instance_id).and_return('id') }
    it do
      expect(PeriodicReport).to receive(:periodic_push_message).with(user.id, options).and_return('message')
      expect(CreatePushNotificationWorker).to receive(:perform_async).with(user.id, '', 'message', request_id: 1)
      subject
    end
  end

  describe '#send_direct_message' do
    let(:options) { {} }
    subject { worker.send_direct_message(user, options) }

    it do
      expect(PeriodicReport).to receive_message_chain(:periodic_message, :deliver!).with(user.id, options).with(no_args)
      subject
    end

    context 'an exception is raised' do
      let(:options) { {} }
      before { allow(worker).to receive(:handle_weird_error).and_raise('anything') }

      context 'the exception is Twitter::Error::EnhanceYourCalm' do
        before { allow(DirectMessageStatus).to receive(:enhance_your_calm?).with(anything).and_return(true) }
        it do
          expect(worker).to receive(:retry_current_report).with(user.id, options, exception: instance_of(RuntimeError))
          expect { subject }.not_to raise_error
        end
      end

      context 'the exception is ignorable' do
        before { allow(worker).to receive(:ignorable_report_error?).with(anything).and_return(true) }
        it { expect { subject }.not_to raise_error }
      end

      context 'the exception is unknown' do
        it { expect { subject }.to raise_error('anything') }
      end
    end
  end

  describe '#send_message_from_egotter' do
    subject { worker.send_message_from_egotter('uid', 'message', 'options') }
    it do
      expect(PeriodicReport).to receive(:build_direct_message_event).
          with('uid', 'message', 'options').and_return('event')
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(event: 'event')
      subject
    end
  end

  describe '#handle_weird_error' do
    let(:error) { RuntimeError.new('anything') }
    let(:block) { Proc.new { raise error } }
    subject { worker.handle_weird_error(user, &block) }

    context 'the error is weird' do
      let(:message) { PeriodicReport.cannot_send_messages_message.message }
      before { allow(worker).to receive(:weird_error?).with(error, user).and_return(true) }

      it do
        expect(worker).to receive(:send_message_from_egotter).with(user.uid, message)
        subject
      end
    end

    context 'else' do
      it { expect { subject }.to raise_error(error) }
    end
  end

  describe '#weird_error?' do
    let(:error) { 'error' }
    subject { worker.weird_error?(error, user) }

    it do
      expect(DirectMessageStatus).to receive(:cannot_send_messages?).with(error).and_return(true)
      expect(PeriodicReport).to receive(:messages_allotted?).with(user).and_return(true)
      is_expected.to be_truthy
    end
  end
end
