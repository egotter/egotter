require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Builder do
  describe '.build_by' do
    let(:t_user) { Hashie::Mash.new(id: 1, screen_name: 'sn') }
    let(:twitter_user) { TwitterUser.build_by(user: t_user) }

    it 'returns TwitterUser' do
      expect(twitter_user).to be_a_kind_of(TwitterUser)
      expect(twitter_user.uid).to eq(t_user.id)
      expect(twitter_user.screen_name).to eq(t_user.screen_name)
    end
  end
end