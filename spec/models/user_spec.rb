require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe '.config' do
    let(:config_keys) { %i(access_token access_token_secret uid screen_name) }

    context 'without option' do
      let(:config) { user.config }

      it 'returns Hash' do
        expect(config).to be_a_kind_of(Hash)
        config_keys.each do |key|
          expect(config.has_key?(key)).to be_truthy
        end
      end
    end
  end

  describe '.api_client' do
    it 'returns ExTwitter' do
      client = user.api_client
      expect(client).to be_a_kind_of(ExTwitter)
      expect(client.uid).to eq(user.uid)
      expect(client.screen_name).to eq(user.screen_name)
    end
  end
end
