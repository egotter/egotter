require 'rails_helper'

RSpec.describe Api::V1::ProfilesController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    request.headers['HTTP_X_CSRF_TOKEN'] = 'token'
    allow(controller).to receive(:valid_uid?).with(twitter_user.uid.to_s)
  end

  describe 'GET #show' do
    render_views

    context 'user is found' do
      before { create(:twitter_db_user, uid: twitter_user.uid) }

      it do
        get :show, params: {uid: twitter_user.uid}
        expect(JSON.parse(response.body).has_key?('html')).to be_truthy
      end

    end

    context 'user is not found' do
      it do
        get :show, params: {uid: twitter_user.uid}
        expect(JSON.parse(response.body).has_key?('error')).to be_truthy
      end
    end
  end
end
