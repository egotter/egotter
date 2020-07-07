require 'rails_helper'

RSpec.describe TwitterDB::Status, type: :model do
  let(:user) { build(:twitter_db_user) }
  let(:twitter_user) { build(:twitter_user, uid: user.uid, screen_name: user.screen_name) }

  describe '.collect_raw_attrs' do
    let(:output) { {id: 1}.to_json }
    subject { described_class.send(:collect_raw_attrs, input) }

    context 'With symbol key' do
      let(:input) { {id: 1} }
      it { is_expected.to eq(output) }
    end

    context 'With string key' do
      let(:input) { {'id' => 1} }
      it { is_expected.to eq(output) }
    end

    context 'With Hashie::Mash with symbol key' do
      let(:input) { Hashie::Mash.new(id: 1) }
      it { is_expected.to eq(output) }
    end

    context 'With Hashie::Mash with string key' do
      let(:input) { Hashie::Mash.new('id' => 1) }
      it { is_expected.to eq(output) }
    end
  end
end
