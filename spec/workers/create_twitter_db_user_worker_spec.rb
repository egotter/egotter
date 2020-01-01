require 'rails_helper'

RSpec.describe CreateTwitterDBUserWorker do
  let(:bot) { create(:bot) }
  let(:client) { bot.api_client }
  let(:user) { create(:user) }
  let(:uids) { [1, 2] }
  let(:worker) { CreateTwitterDBUserWorker.new }

  describe '#perform' do
    let(:options) { {'user_id' => 'ui', 'force_update' => 'fu', 'enqueued_by' => 'eb'} }
    subject { worker.perform(uids, options) }

    before { allow(worker).to receive(:pick_client).with(options).and_return('client') }

    it do
      expect(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(uids, client: 'client', force_update: 'fu')
      subject
    end

    context '#fetch_and_import! raises something unknown exception' do
      let(:exception) { RuntimeError.new('Unknown') }
      before { allow(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(any_args).and_raise(exception) }
      it do
        expect(worker).to receive(:notify_airbrake).with(exception)
        subject
        expect(worker).to satisfy { |w| w.instance_variable_get(:@retries) == 2 }
      end
    end

    context '#fetch_and_import! raises something retryable exception' do
      let(:exception) { RuntimeError.new('Retryable') }
      before do
        allow(TwitterDB::User::Batch).to receive(:fetch_and_import!).with(any_args).and_raise(exception)
        allow(worker).to receive(:meet_requirements_for_retrying?).with(exception).and_return(true)
      end
      it do
        expect(Bot).to receive(:api_client).twice
        expect(worker).to receive(:notify_airbrake).with(exception)
        subject
        expect(worker).to satisfy { |w| w.instance_variable_get(:@retries) == 0 }
      end
    end
  end

  describe '#meet_requirements_for_retrying?' do
    subject { worker.meet_requirements_for_retrying?(exception) }

    context 'Twitter::Error::Unauthorized is raised' do
      let(:exception) { Twitter::Error::Unauthorized.new('Invalid or expired token.') }
      it { is_expected.to be_truthy }
    end

    context 'Twitter::Error::Unauthorized is raised' do
      let(:exception) { Twitter::Error::Forbidden.new('Message') }
      it { is_expected.to be_truthy }
    end

    context 'Connection reset by peer' do
      let(:exception) { RuntimeError.new('Connection reset by peer') }
      it { is_expected.to be_truthy }
    end

    context 'Unknown exception is raised' do
      let(:exception) { RuntimeError.new('Unknown') }
      it { is_expected.to be_falsey }
    end
  end

  describe '#pick_client' do
    let(:options) { {'user_id' => user_id} }
    let(:client) { 'client' }
    subject { worker.pick_client(options) }

    context 'The user_id is not set' do
      let(:user_id) { nil }
      it do
        expect(Bot).to receive(:api_client).and_return(client)
        is_expected.to eq(client)
      end
    end

    context 'The user_id is -1' do
      let(:user_id) { -1 }
      it do
        expect(Bot).to receive(:api_client).and_return(client)
        is_expected.to eq(client)
      end
    end

    context 'The user_id is set but the user is unauthorized' do
      let(:user) { instance_double('User') }
      let(:user_id) { 100 }
      before do
        allow(User).to receive(:find).with(user_id).and_return(user)
        allow(user).to receive(:authorized?).and_return(false)
      end
      it do
        expect(Bot).to receive(:api_client).and_return(client)
        is_expected.to eq(client)
      end
    end

    context 'The user_id is set and the user is authorized' do
      let(:user) { instance_double('User') }
      let(:user_id) { 100 }
      before do
        allow(User).to receive(:find).with(user_id).and_return(user)
        allow(user).to receive(:authorized?).and_return(true)
      end
      it do
        expect(Bot).not_to receive(:api_client)
        expect(user).to receive(:api_client).and_return(client)
        is_expected.to eq(client)
      end
    end
  end
end
