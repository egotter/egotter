require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform('uids', 'options') }
    before { allow(worker).to receive(:pick_client).with('options').and_return('client') }

    it do
      expect(worker).to receive(:do_perform).with('client', 'uids', 'options')
      subject
    end
  end

  describe '#do_perform' do
    let(:uids) { 'uids' }
    let(:client) { double('client') }
    let(:options) { {'user_id' => 'ui', 'force_update' => 'fu', 'enqueued_by' => 'eb'} }
    subject { worker.send(:do_perform, client, uids, options) }

    it do
      expect(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(uids, client: client, force_update: 'fu')
      subject
    end

    context '#fetch_and_import! raises exception' do
      let(:error) { RuntimeError.new }
      before { allow(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(uids, client: client, force_update: 'fu').and_raise(error) }

      context 'the exception is retryable' do
        before { allow(worker).to receive(:exception_handler).with(error, options) }
        it do
          expect(Bot).to receive(:api_client).and_return('bot_client')
          allow(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(uids, client: 'bot_client', force_update: 'fu')
          subject
        end
      end

      context 'the exception is not retryable' do
        before { allow(worker).to receive(:exception_handler).with(error, options).and_raise(error) }
        it do
          expect(Bot).not_to receive(:api_client)
          expect { subject }.to raise_error(error)
        end
      end
    end
  end

  describe 'exception_handler' do
    let(:error) { 'error' }
    subject { worker.send(:exception_handler, error, 'options') }

    it do
      expect(worker).to receive(:log_error?).with(error)
      expect(worker).to receive(:meet_requirements_for_retrying?).with(error)
      expect { subject }.to raise_error(described_class::RetryExhausted)
    end

    context 'meet_requirements_for_retrying? returns true' do
      before { allow(worker).to receive(:meet_requirements_for_retrying?).with(error).and_return(true) }
      it { expect { subject }.not_to raise_error }

      context 'retry is repeated' do
        it do
          expect { 3.times { worker.send(:exception_handler, error, 'options') } }.to raise_error(described_class::RetryExhausted)
        end
      end
    end
  end

  describe 'log_error?' do
    let(:error) { 'error' }
    subject { worker.send(:log_error?, error) }
    it do
      expect(AccountStatus).to receive(:unauthorized?).with(error)
      expect(AccountStatus).to receive(:temporarily_locked?).with(error)
      expect(AccountStatus).to receive(:too_many_requests?).with(error)
      is_expected.to be_truthy
    end
  end

  describe 'meet_requirements_for_retrying?' do
    let(:error) { 'error' }
    subject { worker.send(:meet_requirements_for_retrying?, error) }
    it do
      expect(AccountStatus).to receive(:unauthorized?).with(error).and_return(false)
      expect(AccountStatus).to receive(:forbidden?).with(error).and_return(false)
      expect(AccountStatus).to receive(:too_many_requests?).with(error).and_return(false)
      expect(ServiceStatus).to receive(:retryable_error?).with(error).and_return(false)
      is_expected.to be_falsey
    end
  end

  describe '#pick_client' do
    let(:options) { {'user_id' => user_id} }
    subject { worker.send(:pick_client, options) }

    shared_examples 'it returns bot client' do
      it do
        expect(Bot).to receive(:api_client).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user_id is not set' do
      let(:user_id) { nil }
      include_examples 'it returns bot client'
    end

    context 'user_id is -1' do
      let(:user_id) { -1 }
      include_examples 'it returns bot client'
    end

    context 'user_id is set but the user is not persisted' do
      let(:user_id) { 123 }
      include_examples 'it returns bot client'
    end

    context 'user_id is set but the user is unauthorized' do
      let(:user) { create(:user, authorized: false) }
      let(:user_id) { user.id }
      include_examples 'it returns bot client'
    end

    context 'user_id is set and the user is authorized' do
      let(:user) { create(:user) }
      let(:user_id) { user.id }
      before do
        allow(User).to receive(:find_by).with(id: user_id).and_return(user)
      end
      it do
        expect(user).to receive(:api_client).and_return('result')
        is_expected.to eq('result')
      end
    end
  end

end
