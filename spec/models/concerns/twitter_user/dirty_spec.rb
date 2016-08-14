require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Dirty do
  subject(:tu) { build(:twitter_user) }

  describe '#diff' do
    context 'with same record' do
      subject(:new_tu) do
        create_same_record!(tu)
      end

      it 'returns empty hash' do
        expect(tu.diff(new_tu).keys).to be_empty
      end
    end

    context 'with different record' do
      subject(:new_tu) do
        create_same_record!(tu)
      end

      before do
        new_tu.friends.first.destroy
        new_tu.reload
        adjust_user_info(new_tu)
      end

      it 'returns hash with keys' do
        expect(tu.diff(new_tu).keys).to match_array(%i(friends_count friend_uids))
      end
    end
  end
end