require 'rails_helper'

RSpec.describe Bot, type: :model do
  describe '.current_ids' do
    subject { Bot.send(:current_ids) }

    context 'authorized == true' do
      let!(:bot) { create(:bot, authorized: true) }
      it { is_expected.to match([bot.id]) }
    end

    context 'authorized == false' do
      let!(:bot) { create(:bot, authorized: false) }
      it { is_expected.to be_empty }
    end
  end
end
