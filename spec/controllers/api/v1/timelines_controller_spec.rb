require 'rails_helper'

RSpec.describe Api::V1::TimelinesController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    request.headers['HTTP_REFERER'] = 'referer'
    request.headers['HTTP_X_CSRF_TOKEN'] = 'token'
    allow(controller).to receive(:valid_uid?).with(twitter_user.uid.to_s)
    allow(controller).to receive(:twitter_user_persisted?).with(twitter_user.uid.to_s)
    allow(TwitterUser).to receive(:latest_by).with(uid: twitter_user.uid.to_s).and_return(twitter_user)
  end

  describe 'GET #show' do
    it do
      get :show, params: {uid: twitter_user.uid}, xhr: true
      expect(JSON.parse(response.body).has_key?('html')).to be_truthy
    end
  end
end
