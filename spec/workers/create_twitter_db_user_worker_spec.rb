require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
  end

  describe '.compress_and_perform_async' do
    let(:options) { {} }
    subject { described_class.compress_and_perform_async(uids, options) }

    context 'uids.size is 50' do
      let(:uids) { (1..50).to_a }
      let(:compressed_uids) { described_class.compress((1..50).to_a) }
      let(:new_options) { {compressed: true} }
      it do
        expect(described_class).to receive(:perform_async).with(compressed_uids, new_options)
        subject
      end
    end

    context 'uids.size is 150' do
      let(:uids) { (1..150).to_a }
      let(:compressed_uids1) { described_class.compress((1..100).to_a) }
      let(:compressed_uids2) { described_class.compress((101..150).to_a) }
      let(:new_options) { {compressed: true} }
      it do
        expect(described_class).to receive(:perform_async).with(compressed_uids1, new_options)
        expect(described_class).to receive(:perform_async).with(compressed_uids2, new_options)
        subject
      end
    end
  end

  describe '#perform' do
    let(:uids) { [1] }
    let(:options) { {'user_id' => user.id} }
    let(:client) { 'client' }
    subject { worker.perform(uids, options) }

    before do
      allow(user).to receive(:api_client).and_return(client)
    end

    it do
      expect(worker).to receive(:do_perform).with(client, uids, options)
      subject
    end

    context 'user_id is not set' do
      let(:options) { {} }
      it do
        expect(Bot).to receive(:api_client).and_return(client)
        expect(worker).to receive(:do_perform).with(client, uids, options)
        subject
      end
    end

    context 'uids is compressed' do
      let(:raw_uids) { [1] }
      let(:uids) { described_class.compress(raw_uids) }
      it do
        expect(worker).to receive(:do_perform).with(client, raw_uids, options)
        subject
      end
    end

    context 'error is raised' do
      let(:error) { RuntimeError.new }
      before { allow(worker).to receive(:do_perform).with(any_args).and_raise(error) }
      it do
        expect(worker).to receive(:handle_worker_error).with(error, uids: uids, options: options)
        expect(FailedCreateTwitterDBUserWorker).to receive(:perform_async).with(uids, options.merge(klass: described_class))
        subject
      end
    end
  end

  describe '#do_perform' do
    let(:uids) { 'uids' }
    let(:client) { 'client' }
    let(:options) { {'user_id' => 'ui', 'force_update' => 'fu', 'enqueued_by' => 'eb'} }
    subject { worker.send(:do_perform, client, uids, options) }

    it do
      expect(TwitterDBUserBatch).to receive_message_chain(:new, :import!).with(client).with(uids, force_update: 'fu')
      subject
    end

    context 'TwitterDBUserBatch raises exception' do
      let(:error) { RuntimeError.new }
      before { allow(TwitterDBUserBatch).to receive(:new).with(client).and_raise(error) }

      context 'the exception is retryable' do
        let(:bot_client) { 'bot_client' }
        before do
          allow(worker).to receive(:exception_handler).with(error)
          allow(Bot).to receive(:api_client).and_return(bot_client)
        end
        it do
          expect(TwitterDBUserBatch).to receive_message_chain(:new, :import!).with(bot_client).with(uids, force_update: 'fu')
          subject
        end
      end

      context 'the exception is not retryable' do
        before { allow(worker).to receive(:exception_handler).with(error).and_raise(error) }
        it do
          expect(Bot).not_to receive(:api_client)
          expect { subject }.to raise_error(error)
        end
      end
    end
  end

  describe 'exception_handler' do
    let(:error) { 'error' }
    subject { worker.send(:exception_handler, error) }

    it do
      expect(worker).to receive(:meet_requirements_for_retrying?).with(error)
      expect { subject }.to raise_error(described_class::RetryExhausted)
    end

    context 'meet_requirements_for_retrying? returns true' do
      before { allow(worker).to receive(:meet_requirements_for_retrying?).with(error).and_return(true) }
      it { expect { subject }.not_to raise_error }

      context 'retry is repeated' do
        before { 3.times { worker.send(:exception_handler, error) } }
        it do
          expect { subject }.to raise_error(described_class::RetryExhausted)
        end
      end
    end
  end

  describe 'meet_requirements_for_retrying?' do
    subject { worker.send(:meet_requirements_for_retrying?, error) }
    [
        Twitter::Error::Unauthorized.new('Invalid or expired token.'),
        Twitter::Error::Forbidden.new('To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.'),
        Twitter::Error::Forbidden.new,
        Twitter::Error::TooManyRequests.new,
        RuntimeError.new('Connection reset by peer'),
    ].each do |error_value|
      context "#{error_value} is raised" do
        let(:error) { error_value }
        it { is_expected.to be_truthy }
      end
    end
  end
end
