require 'rails_helper'

RSpec.describe TwitterDB::Status, type: :model do
  let(:user) { build(:twitter_db_user) }
  let(:twitter_user) { build(:twitter_user, uid: user.uid, screen_name: user.screen_name) }

  describe '.import_by!' do
    subject { described_class.import_by!(twitter_user: twitter_user) }
    it do
      expect(described_class).to receive(:import_from!).with(twitter_user.uid, twitter_user.screen_name, twitter_user.statuses)
      subject
    end
  end

  describe '.import_from!' do
    subject { described_class.import_from!(twitter_user.uid, twitter_user.screen_name, twitter_user.statuses) }
    it do
      expect { subject }.to change { described_class.all.size }.by(twitter_user.statuses.size)
    end
  end

  describe '.collect_raw_attrs' do
    let(:method_name) { :collect_raw_attrs }
    it_should_behave_like 'Accept any kind of keys'
  end
end
