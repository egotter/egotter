require 'rails_helper'

RSpec.describe ApiClient, type: :model do
  let(:option) do
    {
        consumer_key: 'ck',
        consumer_secret: 'cs',
        access_token: 'at',
        access_token_secret: 'ats',
    }
  end

  describe '#create_direct_message_event' do
    let(:client) { TwitterWithAutoPagination::Client.new }
    let(:twitter) { double('twitter') }
    let(:instance) { ApiClient.new(client) }
    subject { instance.create_direct_message_event(1, 'text') }

    before { allow(client).to receive(:twitter).and_return(twitter) }

    it do
      expect(twitter).to receive(:create_direct_message_event).with(1, 'text').and_return(message_create: {message_data: {text: 'text'}})
      expect(subject).to satisfy do |dm|
        dm.truncated_message == 'text'
      end
    end
  end

  describe '#method_missing' do
    let(:client) { TwitterWithAutoPagination::Client.new }
    let(:instance) { ApiClient.new(client) }

    let(:method_name) { :user }
    let(:args) { ['ts_3156'] }

    it 'calls ApiClient.do_request_with_retry' do
      expect(client).to receive(:respond_to?).with(method_name).and_call_original
      expect(ApiClient).to receive(:do_request_with_retry).with(client, method_name, args)
      instance.user('ts_3156')
    end
  end

  describe '.do_request_with_retry' do
    let(:client) { instance_double(TwitterWithAutoPagination::Client) }
    let(:method_name) { :user }
    let(:args) { ['ts_3156'] }
    subject { ApiClient.do_request_with_retry(client, method_name, args) }

    it 'passes params to client' do
      expect(client).to receive(method_name).with(*args)
      subject
    end

    context 'The client raises unauthorized exception' do
      let(:exception) { Twitter::Error::Unauthorized.new('Invalid or expired token.') }
      before do
        allow(client).to receive(method_name).with(*args).and_raise(exception)
      end

      it do
        expect(client).to receive(method_name).with(*args)
        expect(AccountStatus).to receive(:unauthorized?).with(exception)
        expect { subject }.to raise_error(Twitter::Error::Unauthorized)
      end
    end

    context 'The client raises retryable exception' do
      before do
        allow(client).to receive(method_name).with(*args).and_raise(Twitter::Error::InternalServerError)
      end

      it do
        expect(client).to receive(method_name).with(*args).exactly(6).times
        expect { subject }.to raise_error(Twitter::Error::InternalServerError)
      end
    end
  end

  describe '.config' do
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
    subject { ApiClient.instance }

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

  describe '.logger' do
    it 'calls Rails.logger' do
      expect(Rails).to receive(:logger).with(no_args)
      ApiClient.logger
    end
  end

  describe '#logger' do
    it 'calls ApiClient.logger' do
      expect(ApiClient).to receive(:logger).with(no_args)
      ApiClient.new(nil).send(:logger)
    end
  end
end
