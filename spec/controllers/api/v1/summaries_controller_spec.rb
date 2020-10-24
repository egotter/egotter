require 'rails_helper'

RSpec.describe Api::V1::SummariesController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    request.headers['HTTP_X_CSRF_TOKEN'] = 'token'
    allow(controller).to receive(:valid_uid?).with(twitter_user.uid.to_s)
    allow(controller).to receive(:twitter_user_persisted?).with(twitter_user.uid.to_s)
    allow(TwitterUser).to receive(:latest_by).with(uid: twitter_user.uid.to_s).and_return(twitter_user)
    allow(controller).to receive(:protected_search?).with(any_args).and_return(false)
    allow(controller).to receive(:blocked_search?).with(any_args).and_return(false)
  end

  describe 'GET #show' do
    let(:summary_hash) do
      {
          one_sided_friends: 1,
          one_sided_followers: 2,
          mutual_friends: 3,
          unfriends: 4,
          unfollowers: 5,
          mutual_unfriends: 6,
      }
    end
    before { allow(twitter_user).to receive(:to_summary).and_return(summary_hash) }

    it do
      get :show, params: {uid: twitter_user.uid}
      expect(response.body).to eq(summary_hash.to_json)
    end
  end
end
