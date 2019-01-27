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
    it 'returns TwitterWithAutoPagination::Client' do
      expect(ApiClient.instance).to be_a_kind_of(ApiClient)
    end
  end

  describe '.better_client' do
    let(:user) { create(:user) }

    context 'target user is persisted' do
      it 'returns a client of target user' do
        client = ApiClient.better_client(user.uid)
        expect(client.access_token).to eq(user.token)
        expect(client.access_token_secret).to eq(user.secret)
      end
    end

    context 'target user is not persisted and target twitter_user is persisted' do
      let(:twitter_user) { build(:twitter_user) }
      let(:user2) { create(:user) }
      before do
        user.update!(authorized: false)
        twitter_user.tap { |tu| tu.uid = user.uid }.save!
        user2.update!(uid: twitter_user.followers[0].uid)
      end

      it 'returns a client of follower' do
        client = ApiClient.better_client(user.uid)
        expect(client.access_token).to eq(user2.token)
        expect(client.access_token_secret).to eq(user2.secret)
      end
    end

    context 'both target user and target twitter_user are not persisted' do
      let(:bot) { create(:bot) }
      before do
        user.update!(authorized: false)
        bot
        Bot::IDS = Bot.pluck(:id)
      end
      it 'returns a client of bot' do
        client = ApiClient.better_client(user.uid)
        expect(client.access_token).to eq(bot.token)
        expect(client.access_token_secret).to eq(bot.secret)
      end
    end
  end

  describe '.user_or_bot_client' do
    let(:bot) { create(:bot) }
    before do
      bot
      Bot::IDS = Bot.pluck(:id)
    end

    context 'user_id == -1' do
      let(:user_id) { -1 }
      it 'calls Bot.sample' do
        expect(Bot).to receive(:sample).and_return(Bot.first)
        ApiClient.user_or_bot_client(user_id)
      end
    end

    context 'user_id == nil' do
      let(:user_id) { nil }
      it 'calls Bot.sample' do
        expect(Bot).to receive(:sample).and_return(Bot.first)
        ApiClient.user_or_bot_client(user_id)
      end
    end

    context 'user_id != -1' do
      let(:user) { create(:user) }
      let(:user_id) { user.id }
      it 'calls User.find' do
        expect(User).to receive(:find).with(user_id).and_return(User.first)
        ApiClient.user_or_bot_client(user_id)
      end
    end
  end
end
