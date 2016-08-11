require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Utils do
  subject(:tu) { build(:twitter_user) }

  describe '#search_and_touch' do
    before { tu.save! }
    it 'increments search_count' do
      expect { tu.search_and_touch }.to change { tu.search_count }.by(1)
    end
  end

  describe '#update_and_touch' do
    before { tu.save! }
    it 'increments update_count' do
      expect { tu.update_and_touch }.to change { tu.update_count }.by(1)
    end
  end
end