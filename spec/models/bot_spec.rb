require 'rails_helper'

RSpec.describe Bot, type: :model do
  describe '.current_ids' do
    context 'authorized == true' do
      let!(:bot) { create(:bot, authorized: true) }
      it { expect(Bot.current_ids).to match([bot.id]) }
    end

    context 'authorized == false' do
      let!(:bot) { create(:bot, authorized: false) }
      it { expect(Bot.current_ids).to be_empty }
    end
  end
end
