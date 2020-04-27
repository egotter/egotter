require 'rails_helper'

RSpec.describe TwitterDB::Status, type: :model do
  let(:user) { build(:twitter_db_user) }
  let(:twitter_user) { build(:twitter_user, uid: user.uid, screen_name: user.screen_name) }

  describe '.collect_raw_attrs' do
    let(:method_name) { :collect_raw_attrs }
    it_should_behave_like 'Accept any kind of keys'
  end
end
