require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Dirty do
  subject(:tu) { build(:twitter_user) }

  describe '#diff' do
    context 'with same record' do
      subject(:copy) { copy_twitter_user(tu) }

      it 'returns empty hash' do
        expect(tu.diff(copy).keys).to be_empty
      end
    end

    context 'with different record' do
      subject(:copy) { copy_twitter_user(tu) }

      before do
        copy.friendships.first.destroy
        copy.reload
        adjust_user_info(copy)
      end

      it 'returns hash with keys' do
        expect(tu.diff(copy).keys).to match_array(%i(friends_count friend_uids))
      end
    end
  end
end