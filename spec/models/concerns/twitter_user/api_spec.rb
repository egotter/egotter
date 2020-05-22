require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Api do
  let(:twitter_user) { create(:twitter_user, with_relations: true) }

  describe '#mutual_friend_uids' do
    subject { twitter_user.mutual_friend_uids }
    it do
      expect(twitter_user).to receive_message_chain(:mutual_friendships, :pluck).with(:friend_uid).and_return('result')
      is_expected.to eq('result')
    end
  end
end
