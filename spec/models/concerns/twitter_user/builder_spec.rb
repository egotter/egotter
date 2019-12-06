require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Builder do
  describe '.build_by' do
    let(:user) do
      {
          id: 1,
          screen_name: 'sn',
          friends_count: 123,
          followers_count: 456,
      }
    end
    subject { TwitterUser.build_by(user: user) }

    it { is_expected.to be_a_kind_of(TwitterUser) }

    it do
      is_expected.to have_attributes(
                         uid: user[:id],
                         screen_name: user[:screen_name],
                         friends_count: user[:friends_count],
                         followers_count: user[:followers_count],
                         raw_attrs_text: TwitterUser.collect_user_info(user)
                     )
    end
  end
end