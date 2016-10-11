require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe '.config' do
    let(:config_keys) { %i(access_token access_token_secret) }

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
    it 'returns Twitter::REST::Client' do
      client = user.api_client
      expect(client).to be_a_kind_of(Twitter::REST::Client)
      expect(client.access_token).to eq(user.token)
      expect(client.access_token_secret).to eq(user.secret)
    end
  end
end
