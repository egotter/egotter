require 'rails_helper'

RSpec.describe Concerns::TwitterDB::User::Associations do
  describe '.where_and_order_by_field' do
    let(:uids) { [1, 2, 3] }
    before do
      uids.map do |uid|
        create(:twitter_db_user, uid: uid)
      end
    end

    it 'fetches users sorted by values of uids' do
      randomized_uids = uids.shuffle
      randomized_users = TwitterDB::User.where_and_order_by_field(uids: randomized_uids)
      randomized_uids.zip(randomized_users).each do |uid, user|
        expect(uid).to eq(user.uid)
      end
    end
  end
end
