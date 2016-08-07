require 'rails_helper'

RSpec.describe Bot, type: :model do
  describe '.init' do
    it 'returns nil' do
      expect(Bot.init).to be_nil
    end
  end

  describe '.sample' do
    it 'returns true' do
      expect(Bot.sample).to be_truthy
    end
  end

  describe '.size' do
    it 'returns true' do
      expect(Bot.size).to be_a_kind_of(Integer)
    end
  end

  describe '.empty?' do
    it 'returns false' do
      expect(Bot.empty?).to be_falsey
    end
  end

  describe '.select_bot' do
    let(:screen_name) { 'test_bot' }
    let(:bot) { Bot.select_bot(screen_name) }

    it 'returns Hash with specified screen_name' do
      expect(bot).to be_a_kind_of(Hash)
      expect(bot[:screen_name]).to eq(screen_name)
    end
  end

  describe '.config' do
    let(:config_keys) { %i(access_token access_token_secret uid screen_name) }

    context 'specify screen_name' do
      let(:screen_name) { 'test_bot' }
      let(:config) { Bot.config(screen_name: screen_name) }

      it 'returns Hash with specified screen_name' do
        expect(config).to be_a_kind_of(Hash)
        expect(config[:screen_name]).to eq(screen_name)
      end
    end

    context 'without option' do
      let(:config) { Bot.config }

      it 'returns Hash' do
        expect(config).to be_a_kind_of(Hash)
        config_keys.each do |key|
          expect(config.has_key?(key)).to be_truthy
        end
      end
    end

    context 'with invalid option' do
      let(:invalid_option) { {screen_name: nil} }
      let(:config) { Bot.config(invalid_option) }

      it "doesn't override config" do
        config_keys.each do |key|
          expect(invalid_option[key]).to_not eq(config[key])
        end
      end
    end
  end

  describe '.screen_names' do
    let(:screen_names) { ['test_bot'] }

    it 'returns correct screen_names' do
      expect(Bot.screen_names).to match_array(screen_names)
    end
  end
end
