require 'rails_helper'

RSpec.describe TwitterClient, type: :model do
  let(:api_client) { double('api_client') }
  let(:twitter) { double('twitter') }
  let(:instance) { described_class.new(api_client, twitter) }

  [:user_agent, :user_token?, :credentials, :proxy, :timeouts].each do |method|
    describe "##{method}" do
      let(:args) { [1] }
      let(:kwargs) { {} }
      it do
        expect(twitter).to receive(method).with(*args, **kwargs)
        instance.send(method, *args, **kwargs)
      end
    end
  end

  [:friend_ids, :follower_ids, :friendship?, :destroy_status, :unfavorite!,
   :user, :users, :user?, :status, :friendships_outgoing, :muted_ids, :blocked_ids,
   :favorites, :update, :update!, :verify_credentials, :follow!, :unfollow, :user_timeline].each do |method|
    describe "##{method}" do
      let(:args) { [] }
      let(:kwargs) { {} }
      it do
        expect(instance).to receive(:call_api).with(method, *args, kwargs)
        instance.send(method, *args, kwargs)
      end
    end
  end

  describe 'create_direct_message_event' do
    context 'Pass uid and message' do
      subject { instance.create_direct_message_event(1, 'text') }
      it do
        expect(DirectMessageReceiveLog).to receive(:message_received?).with(1).and_return(true)
        expect(instance).to receive(:call_api).with(:create_direct_message_event, 1, 'text')
        subject
      end
    end

    context 'Pass event' do
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
      subject { instance.create_direct_message_event(event: event) }
      it do
        expect(DirectMessageReceiveLog).to receive(:message_received?).with(1).and_return(true)
        expect(instance).to receive(:call_api).with(:create_direct_message_event, event: event)
        subject
      end
    end
  end

  describe '#safe_users' do
    let(:api_client) { double('api_client', app_context: true, owner: nil) }
    subject { instance.safe_users([1]) }
    it do
      expect(instance).to receive(:users).with([1]).and_return([{id: 1}])
      subject
    end

    context 'all users are suspended' do
      let(:error) { RuntimeError.new }
      before do
        allow(instance).to receive(:users).and_raise(error)
        allow(TwitterApiStatus).to receive(:no_user_matches?).with(error).and_return(true)
      end
      it { is_expected.to eq([]) }
    end

    context 'retryable exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(instance).to receive(:users).and_raise(error).exactly(4).times }

      context 'exception responds TwitterApiStatus.unauthorized?' do
        before do
          allow(TwitterApiStatus).to receive(:unauthorized?).with(error).and_return(true)
        end
        it do
          expect(instance).to receive(:reload).exactly(3).times
          expect { subject }.to raise_error(ApiClient::RetryExhausted)
        end
      end
    end
  end

  describe '#method_missing' do
    subject { instance.send(:method_missing, :user, 1) }
    before { allow(twitter).to receive(:respond_to?).with(:user).and_return(true) }

    it do
      expect(instance).to receive(:call_api).with(:user, 1)
      subject
    end
  end

  describe '#call_api' do
    subject { instance.send(:call_api, :user, 1) }

    it do
      expect(twitter).to receive(:user).with(1).and_return('user_result')
      # expect(CreateTwitterApiLogWorker).to receive(:perform_async).with(name: "TwitterClient#user")
      is_expected.to eq('user_result')
    end

    context 'error is raised' do
      let(:error) { RuntimeError.new }
      before { allow(twitter).to receive(:user).with(1).and_raise(error) }
      it do
        expect(api_client).to receive(:update_authorization_status).with(error)
        expect(api_client).to receive(:update_lock_status).with(error)
        expect { subject }.to raise_error(error)
      end
    end
  end

  describe '#app_context?' do
    subject { instance.app_context? }
    it do
      expect(api_client).to receive(:app_context?)
      subject
    end
  end
end
