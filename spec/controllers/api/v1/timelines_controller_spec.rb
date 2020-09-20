require 'rails_helper'

RSpec.describe Api::V1::TimelinesController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    request.headers['HTTP_X_CSRF_TOKEN'] = 'token'
    allow(controller).to receive(:twitter_user_persisted?).with(any_args).and_return(true)
    allow(controller).to receive(:twitter_db_user_persisted?).with(any_args).and_return(true)
    allow(controller).to receive(:protected_search?).with(any_args).and_return(false)
    allow(TwitterUser).to receive(:latest_by).with(any_args).and_return(twitter_user)
  end

  describe 'GET #summary' do
    before do
      allow(twitter_user).to receive_message_chain(:one_sided_friendships, :size).and_return(1)
      allow(twitter_user).to receive_message_chain(:one_sided_followerships, :size).and_return(2)
      allow(twitter_user).to receive_message_chain(:mutual_friendships, :size).and_return(3)
      allow(twitter_user).to receive_message_chain(:unfriendships, :size).and_return(4)
      allow(twitter_user).to receive_message_chain(:unfollowerships, :size).and_return(5)
      allow(twitter_user).to receive_message_chain(:mutual_unfriendships, :size).and_return(6)
    end

    it do
      get :summary, params: {uid: twitter_user.uid}
      expect(JSON.parse(response.body)).to eq('one_sided_friends' => 1, 'one_sided_followers' => 2, 'mutual_friends' => 3, 'unfriends' => 4, 'unfollowers' => 5, 'blocking_or_blocked' => 6)
    end
  end

  describe 'GET #profile' do
    render_views

    before do
      create(:twitter_db_user, uid: twitter_user.uid)
    end

    it do
      get :profile, params: {uid: twitter_user.uid}
      expect(JSON.parse(response.body).has_key?('html')).to be_truthy
    end
  end
end
