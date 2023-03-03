require 'rails_helper'

RSpec.describe Bot, type: :model do
  describe '.available_ids' do
    subject { Bot.send(:available_ids) }

    context 'authorized == true' do
      let!(:bot) { create(:bot, authorized: true) }
      it { is_expected.to match([bot.id]) }
    end

    context 'authorized == false' do
      let!(:bot) { create(:bot, authorized: false) }
      it { is_expected.to be_empty }
    end
  end

  describe '.api_client' do
    subject { described_class.api_client('options') }
    before { allow(described_class).to receive(:available_ids).and_return([1]) }
    it do
      expect(described_class).to receive_message_chain(:select, :find, :api_client).
          with(:token, :secret).with(1).with('options')
      subject
    end
  end
end
