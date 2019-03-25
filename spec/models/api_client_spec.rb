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
    let(:client) { TwitterWithAutoPagination::Client.new }

    let(:method_name) { :user }
    let(:args) { ['ts_3156'] }

    it 'passes params to client' do
      expect(ApiClient).to receive(:do_request_with_retry).with(client, method_name, args)
      ApiClient.do_request_with_retry(client, method_name, args)
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
    it 'returns ApiClient' do
      expect(ApiClient.instance).to be_a_kind_of(ApiClient)
    end

    context 'With empty options' do
      it do
        expect(TwitterWithAutoPagination::Client).to receive(:new).with(no_args)
        ApiClient.instance
      end
    end
  end
end
