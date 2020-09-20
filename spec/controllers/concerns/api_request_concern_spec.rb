require 'rails_helper'

describe ApiRequestConcern, type: :controller do
  controller ApplicationController do
    include ApiRequestConcern

    def new
    end
  end

  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, uid: user.uid) }

  before do
    request.headers['HTTP_X_CSRF_TOKEN'] = 'token'
    allow(TwitterUser).to receive_message_chain(:with_delay, :latest_by).with(uid: twitter_user.uid.to_s).and_return(twitter_user)
  end

  describe 'before_action callbacks' do
    it do
      expect(controller).to receive(:valid_uid?)
      expect(controller).to receive(:twitter_user_persisted?)
      expect(controller).to receive(:twitter_db_user_persisted?)
      expect(controller).to receive(:protected_search?)
      get :new, params: {uid: user.uid}
    end

    context 'profile_api? returns true' do
      before do
        allow(controller).to receive(:profile_api?).exactly(3).times.and_return(true)
      end

      it do
        expect(controller).to receive(:valid_uid?)
        expect(controller).not_to receive(:twitter_user_persisted?)
        expect(controller).to receive(:twitter_db_user_persisted?)
        expect(controller).not_to receive(:protected_search?)
        get :new, params: {uid: user.uid}
      end
    end
  end
end
