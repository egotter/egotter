require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Builder do
  describe '.build_by' do
    let(:t_user) do
      {
          id: 1,
          screen_name: 'sn',
          friends_count: 123,
          followers_count: 456,
      }
    end

    let(:twitter_user) { TwitterUser.build_by(user: t_user) }

    it 'returns TwitterUser' do
      expect(twitter_user).to be_a_kind_of(TwitterUser)
      expect(twitter_user.uid).to eq(t_user[:id])
      expect(twitter_user.screen_name).to eq(t_user[:screen_name])
      expect(twitter_user.friends_count).to eq(t_user[:friends_count])
      expect(twitter_user.followers_count).to eq(t_user[:followers_count])
    end
  end
end