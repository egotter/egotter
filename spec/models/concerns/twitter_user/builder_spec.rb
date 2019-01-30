require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Builder do
  describe '.build_by' do
    let(:user) { Hashie::Mash.new(id: 1, screen_name: 'sn') }
    let(:tu) { TwitterUser.build_by(user: user) }

    it 'returns TwitterUser' do
      expect(tu).to be_a_kind_of(TwitterUser)
      expect(tu.uid).to eq(user.id.to_s)
      expect(tu.screen_name).to eq(user.screen_name)
    end
  end
end