require 'rails_helper'

RSpec.describe ApiClient, type: :model do
  let(:user) { create(:user) }
  let(:credential_token) { create(:credential_token, user_id: user.id) }
  let(:client) { double('client', access_token: credential_token.token, access_token_secret: credential_token.secret) }
  let(:instance) { ApiClient.new(client, user) }

  describe '#create_direct_message' do
    let(:request) { double('request') }
    subject { instance.create_direct_message(1, 'text') }

    it do
      expect(client).to receive_message_chain(:twitter, :create_direct_message_event).with(1, 'text')
      subject
    end

    context 'async is true' do
      subject { instance.create_direct_message(1, 'text', async: true) }

      before do
        allow(CreateDirectMessageRequest).to receive(:create).with(sender_id: user.uid, recipient_id: 1, properties: {message: 'text'}).and_return(request)
      end

      it do
        expect(request).to receive(:perform)
        subject
      end
    end
  end

  describe '#create_direct_message_event' do
    let(:event) do
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: 1},
              message_data: {
                  text: 'text'
              }
          }
      }
    end
    let(:response) { {message_create: {message_data: {text: 'text'}}} }
    let(:dm) { double('dm', sender_id: 10, recipient_id: 1, text: 'text') }
    subject { instance.create_direct_message_event(event: event) }

    before { allow(instance).to receive(:twitter).and_return(client) }

    it do
      expect(client).to receive(:create_direct_message_event).with(event: event).and_return(response)
      expect(DirectMessageWrapper).to receive(:new).with(event: response).and_return(dm)
      is_expected.to eq(dm)
    end

    context 'an exception is raised' do
      let(:error) { RuntimeError.new('error') }
      before { allow(client).to receive(:create_direct_message_event).and_raise(error) }
      it do
        expect(CreateDirectMessageErrorLogWorker).to receive(:perform_async).
            with(sender_id: user.uid, recipient_id: 1, error_class: error.class, error_message: error.message, properties: {args: {event: event}}, created_at: instance_of(ActiveSupport::TimeWithZone))
        expect(instance).to receive(:update_blocker_status).with(error)
        expect { subject }.to raise_error(error)
      end
    end

    context 'retryable exception is raised' do
      let(:error) { ApiClient::RetryExhausted.new }
      before { allow(client).to receive(:create_direct_message_event).and_raise(error) }
      it do
        expect(CreateDirectMessageEventWorker).to receive(:perform_in).with(5.seconds, user.id, event)
        expect { subject }.to raise_error(ApiClient::MessageWillBeResent)
      end
    end
  end

  describe '#send_report' do
    context 'No button is passed' do
      subject { instance.send_report(1, 'message') }
      it do
        expect(DirectMessageEvent).to receive(:build).with(1, 'message').and_return('event')
        expect(instance).to receive(:create_direct_message_event).with(event: 'event')
        subject
      end
    end

    context 'Buttons are passed' do
      let(:buttons) { ['button'] }
      subject { instance.send_report(1, 'message', buttons) }
      it do
        expect(DirectMessageEvent).to receive(:build_with_replies).with(1, 'message', buttons).and_return('event')
        expect(instance).to receive(:create_direct_message_event).with(event: 'event')
        subject
      end
    end
  end

  [:verify_credentials, :user, :users, :user_timeline, :mentions_timeline, :favorites, :friendship?].each do |method|
    describe "##{method}" do
      let(:args) { [] }
      let(:kwargs) { {} }
      it do
        expect(instance).to receive(:send).with(method, args, kwargs)
        instance.send(method, args, kwargs)
      end
    end
  end

  describe '#method_missing' do
    subject { instance.send(:method_missing, :user, 1) }

    context 'client responds to specified method' do
      before { allow(client).to receive(:respond_to?).with(:user).and_return(true) }
      it do
        expect(instance).to receive(:call_api).with(:user, 1).and_return('user')
        is_expected.to eq('user')
      end
    end

    context "client doesn't respond to specified method" do
      before { allow(client).to receive(:respond_to?).with(:user).and_return(false) }
      it do
        expect(instance).not_to receive(:call_api)
        expect { subject }.to raise_error(NameError) # Or NoMethodError
      end
    end
  end

  describe '#call_api' do
    subject { instance.send(:call_api, :user, 1) }

    it do
      expect(client).to receive(:user).with(1).and_return('user')
      is_expected.to eq('user')
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(client).to receive(:user).with(1).and_raise(error) }
      it do
        expect(instance).to receive(:update_authorization_status).with(error)
        expect(instance).to receive(:update_lock_status).with(error)
        expect(instance).to receive(:create_not_found_user).with(error, 1)
        expect(instance).to receive(:create_forbidden_user).with(error, 1)
        expect { subject }.to raise_error(error)
      end
    end
  end

  describe '#update_blocker_status' do
    let(:error) { RuntimeError.new('error') }
    subject { instance.update_blocker_status(error) }

    before do
      instance.instance_variable_set(:@user, user)
      allow(DirectMessageStatus).to receive(:you_have_blocked?).with(error).and_return(true)
    end

    it do
      expect(CreateViolationEventWorker).to receive(:perform_async).with(user.id, 'Blocking egotter')
      subject
    end
  end

  describe '#update_authorization_status' do
    let(:error) { RuntimeError.new('error') }
    subject { instance.update_authorization_status(error) }

    before do
      instance.instance_variable_set(:@user, user)
      allow(TwitterApiStatus).to receive(:unauthorized?).with(error).and_return(true)
    end

    it do
      expect(UpdateUserAttrsWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#update_lock_status' do
    let(:error) { RuntimeError.new('error') }
    subject { instance.update_lock_status(error) }

    before do
      instance.instance_variable_set(:@user, user)
      allow(TwitterApiStatus).to receive(:temporarily_locked?).with(error).and_return(true)
    end

    it do
      expect(UpdateLockedWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#create_not_found_user' do
    let(:error) { Twitter::Error::NotFound.new('User not found.') }
    subject { instance.create_not_found_user(error, 'name') }
    it do
      expect(CreateNotFoundUserWorker).to receive(:perform_async).with('name', anything)
      subject
    end
  end

  describe '#create_forbidden_user' do
    let(:error) { Twitter::Error::Forbidden.new('User has been suspended.') }
    subject { instance.create_forbidden_user(error, 'name') }
    it do
      expect(CreateForbiddenUserWorker).to receive(:perform_async).with('name', anything)
      subject
    end
  end

  describe '.config' do
    let(:option) do
      {
          consumer_key: 'ck',
          consumer_secret: 'cs',
          access_token: 'at',
          access_token_secret: 'ats',
      }
    end

    context 'without option' do
      let(:config) { ApiClient.config }

      it 'returns Hash' do
        expect(config).to be_a_kind_of(Hash)
        option.each_key do |key|
          expect(config.has_key?(key)).to be_truthy
        end
      end
    end

    context 'with option' do
      let(:config) { ApiClient.config(option) }

      it 'overrides config' do
        option.each_key do |key|
          expect(option[key]).to eq(config[key])
        end
      end
    end
  end

  describe '.instance' do
    subject { described_class.instance }

    it 'returns ApiClient' do
      is_expected.to be_a_kind_of(ApiClient)
    end

    context 'With empty options' do
      it do
        expect(TwitterWithAutoPagination::Client).to receive(:new)
        subject
      end
    end
  end
end
