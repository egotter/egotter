require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:worker) { described_class.new }

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
    let(:user) { create(:user) }
    let(:options) { {'user_id' => user.id} }
    let(:client) { double('client') }
    subject { worker.perform('uids', options) }
    before do
      allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      allow(user).to receive(:api_client).and_return(client)
    end

    it do
      expect(worker).to receive(:do_perform).with(client, 'uids', options)
      subject
    end
  end

  describe '#do_perform' do
    let(:uids) { 'uids' }
    let(:client) { 'client' }
    let(:options) { {'user_id' => 'ui', 'force_update' => 'fu', 'enqueued_by' => 'eb'} }
    subject { worker.send(:do_perform, client, uids, options) }

    it do
      expect(TwitterDBUserBatch).to receive(:fetch_and_import!).with(uids, client: client, force_update: 'fu')
      subject
    end

    context '#fetch_and_import! raises exception' do
      let(:error) { RuntimeError.new }
      before { allow(TwitterDBUserBatch).to receive(:fetch_and_import!).with(uids, client: client, force_update: 'fu').and_raise(error) }

      context 'the exception is retryable' do
        before { allow(worker).to receive(:exception_handler).with(error) }
        it do
          expect(Bot).to receive(:api_client).and_return('client2')
          allow(TwitterDBUserBatch).to receive(:fetch_and_import!).with(uids, client: 'client2', force_update: 'fu')
          subject
        end
      end

      context 'the exception is not retryable' do
        before { allow(worker).to receive(:exception_handler).with(error).and_raise(error) }
        it do
          expect(worker).not_to receive(:pick_client)
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

  describe '#pick_client' do
    let(:options) { {'user_id' => user_id} }
    let(:user) { create(:user) }
    subject { worker.send(:pick_client, options) }

    shared_examples 'it returns bot client' do
      before do
        allow(User).to receive(:pick_authorized_id).and_return(user.id)
        allow(User).to receive(:find).with(user.id).and_return(user)
      end
      it do
        expect(user).to receive(:api_client).and_return('result')
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
