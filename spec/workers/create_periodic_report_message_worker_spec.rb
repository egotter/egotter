require 'rails_helper'

RSpec.describe CreatePeriodicReportMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:options) { {} }
    subject { worker.perform(user.id, options) }

    shared_context 'send dm from egotter' do
      before do
        allow(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).
            with(no_args).with(no_args).with(anything)
      end
    end

    context 'options[:unregistered] is specified' do
      include_context 'send dm from egotter'
      let(:options) { {unregistered: true, uid: 1} }
      it do
        expect(PeriodicReport).to receive(:unregistered_message).and_call_original
        subject
      end
    end

    context 'options[:stop_requested] is specified' do
      include_context 'send dm from egotter'
      let(:options) { {stop_requested: true, uid: 1} }
      it do
        expect(PeriodicReport).to receive(:stop_requested_message).and_call_original
        subject
      end
    end

    context "not_fatal_error? returns true" do
      before do
        allow(options).to receive(:symbolize_keys!).and_raise('anything')
        allow(worker).to receive(:not_fatal_error?).with(anything).and_return(true)
      end
      it do
        expect(worker.logger).to receive(:info).with(instance_of(String))
        subject
      end
    end

    context "unknown exception is raised" do
      before do
        allow(options).to receive(:symbolize_keys!).and_raise('unknown')
      end
      it do
        expect(worker.logger).to receive(:warn).with(instance_of(String))
        subject
      end
    end
  end

  describe '#not_fatal_error?' do
    let(:error) { RuntimeError.new('error') }
    subject { worker.not_fatal_error?(error) }

    %i(
      you_have_blocked?
      not_following_you?
      cannot_find_specified_user?
      protect_out_users_from_spam?
      your_account_suspended?
      cannot_send_messages?
    ).each do |method|
      context "#{method} returns true" do
        before { allow(DirectMessageStatus).to receive(method).with(error).and_return(true) }
        it { is_expected.to be_truthy }
      end
    end

    context "unknown exception is raised" do
      it { is_expected.to be_falsey }
    end
  end
end
