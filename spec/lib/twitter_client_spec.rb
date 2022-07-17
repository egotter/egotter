require 'rails_helper'

RSpec.describe TwitterClient, type: :model do
  let(:api_client) { double('api_client') }
  let(:twitter) { double('twitter') }
  let(:instance) { described_class.new(api_client, twitter) }

  [:user_agent, :user_token?, :credentials, :proxy, :timeouts,
   :friend_ids, :follower_ids, :friendship?, :destroy_status].each do |method|
    describe "##{method}" do
      let(:args) { [] }
      let(:kwargs) { {} }
      it do
        expect(twitter).to receive(:send).with(method, args, kwargs)
        instance.send(method, args, kwargs)
      end
    end
  end

  describe 'verify_credentials' do
    subject { instance.verify_credentials }
    it do
      expect(instance).to receive(:call_api).with(:verify_credentials)
      expect(CreateTwitterApiLogWorker).to receive(:perform_async).with(name: :verify_credentials)
      subject
    end
  end

  describe 'users' do
    subject { instance.users([1, 2, 3]) }
    it do
      expect(instance).to receive(:call_api).with(:users, [1, 2, 3])
      expect(CreateTwitterApiLogWorker).to receive(:perform_async).with(name: :users)
      subject
    end
  end

  describe 'follow!' do
    subject { instance.follow!(1) }
    it do
      expect(instance).to receive(:call_api).with(:follow!, 1)
      expect(CreateTwitterApiLogWorker).to receive(:perform_async).with(name: :follow!)
      subject
    end
  end

  describe 'unfollow' do
    subject { instance.unfollow(1) }
    it do
      expect(instance).to receive(:call_api).with(:unfollow, 1)
      expect(CreateTwitterApiLogWorker).to receive(:perform_async).with(name: :unfollow)
      subject
    end
  end

  describe 'user_timeline' do
    subject { instance.user_timeline(1) }
    it do
      expect(instance).to receive(:call_api).with(:user_timeline, 1)
      expect(CreateTwitterApiLogWorker).to receive(:perform_async).with(name: :user_timeline)
      subject
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
      expect(instance).to receive(:call_api).with(:user, 1)
      subject
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
end
