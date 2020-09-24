require 'rails_helper'

RSpec.describe Api::V1::SummariesController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    request.headers['HTTP_X_CSRF_TOKEN'] = 'token'
    allow(controller).to receive(:valid_uid?).with(twitter_user.uid.to_s)
    allow(controller).to receive(:twitter_user_persisted?).with(twitter_user.uid.to_s)
    allow(TwitterUser).to receive(:latest_by).with(uid: twitter_user.uid.to_s).and_return(twitter_user)
    allow(controller).to receive(:protected_search?).with(any_args).and_return(false)
  end

  describe 'GET #show' do
    before do
      allow(twitter_user).to receive_message_chain(:one_sided_friendships, :size).and_return(1)
      allow(twitter_user).to receive_message_chain(:one_sided_followerships, :size).and_return(2)
      allow(twitter_user).to receive_message_chain(:mutual_friendships, :size).and_return(3)
      allow(twitter_user).to receive_message_chain(:unfriendships, :size).and_return(4)
      allow(twitter_user).to receive_message_chain(:unfollowerships, :size).and_return(5)
      allow(twitter_user).to receive_message_chain(:mutual_unfriendships, :size).and_return(6)
    end

    it do
      get :show, params: {uid: twitter_user.uid}
      expect(JSON.parse(response.body)).to eq('one_sided_friends' => 1, 'one_sided_followers' => 2, 'mutual_friends' => 3, 'unfriends' => 4, 'unfollowers' => 5, 'blocking_or_blocked' => 6)
    end
  end
end
