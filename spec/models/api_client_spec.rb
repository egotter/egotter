require 'rails_helper'

RSpec.describe ApiClient, type: :model do
  describe '.config' do
    let(:option) { {access_token: 'at', access_token_secret: 'ats', uid: 'uid', screen_name: 'sn'} }

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
    it 'returns ExTwitter' do
      expect(ApiClient.instance).to be_a_kind_of(ExTwitter)
    end
  end
end
