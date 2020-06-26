require 'rails_helper'

RSpec.describe Api::V1::SummaryController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    allow(controller).to receive(:twitter_user_persisted?).with(any_args).and_return(true)
    allow(controller).to receive(:twitter_db_user_persisted?).with(any_args).and_return(true)
    allow(controller).to receive(:protected_search?).with(any_args).and_return(false)
    allow(TwitterUser).to receive(:latest_by).with(any_args).and_return(twitter_user)
  end

  describe 'GET #summary' do
    it do
      expect(twitter_user).to receive(:one_sided_friendships).and_return([1])
      expect(twitter_user).to receive(:one_sided_followerships).and_return([1])
      expect(twitter_user).to receive(:mutual_friendships).and_return([1])
      expect(twitter_user).to receive(:unfriendships).and_return([1])
      expect(twitter_user).to receive(:unfollowerships).and_return([1])
      expect(twitter_user).to receive(:mutual_unfriendships).and_return([1])
      get :summary, params: {uid: twitter_user.uid}
    end
  end
end
