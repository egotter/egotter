require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Builder do
  describe '.build_by' do
    let(:user) do
      {
          id: 1,
          screen_name: 'sn',
          followers_count: 456,
          friends_count: 123,
      }
    end
    subject { TwitterUser.build_by(user: user) }

    it { is_expected.to be_a_kind_of(TwitterUser) }

    it do
      is_expected.to have_attributes(
                         uid: user[:id],
                         screen_name: user[:screen_name],
                         friends_count: user[:friends_count],
                         followers_count: user[:followers_count])
      expect(subject.profile_text).to match(user.to_json)
    end
  end

  describe '.filter_save_keys' do
    subject { Concerns::TwitterUser::Builder.filter_save_keys(user) }
    let(:result) { {id: 1}.to_json }

    it do
      expect(TwitterUser.methods).not_to include(:filter_save_keys)
      expect(TwitterUser.new.methods).not_to include(:filter_save_keys)
    end

    context 'With symbol key' do
      let(:user) { {id: 1} }
      it { is_expected.to eq(result) }
    end

    context 'With string key' do
      let(:user) { {'id' => 1} }
      it { is_expected.to eq(result) }
    end

    context 'With Hashie::Mash with symbol key' do
      let(:user) { Hashie::Mash.new(id: 1) }
      it { is_expected.to eq(result) }
    end

    context 'With Hashie::Mash with string key' do
      let(:user) { Hashie::Mash.new('id' => 1) }
      it { is_expected.to eq(result) }
    end
  end
end