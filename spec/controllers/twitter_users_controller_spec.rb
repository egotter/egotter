require 'rails_helper'

RSpec.describe TwitterUsersController, type: :controller do
  describe 'POST #create' do
    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    let(:params_uid) { twitter_user.uid.to_s }
    subject { post :create, params: {uid: twitter_user.uid} }

    it do
      expect(controller).to receive(:reject_crawler)
      expect(controller).to receive(:signed_in_user_authorized?)
      expect(controller).to receive(:enough_permission_level?)
      expect(controller).to receive(:valid_uid?).with(params_uid)
      expect(controller).to receive(:user_requested_self_search_by_uid?).with(params_uid)
      expect(controller).to receive(:build_twitter_user_by_uid).with(params_uid).and_return(twitter_user)
      expect(controller).to receive(:search_limitation_soft_limited?).with(twitter_user)
      expect(controller).to receive(:protected_search?).with(twitter_user).and_return(false)
      expect(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
      expect(controller).to receive(:too_many_searches?).with(twitter_user).and_return(false)
      expect(controller).to receive(:too_many_requests?).with(twitter_user).and_return(false)
      subject
    end

    context 'user_requested_self_search_by_uid? returns true' do
      before do
        allow(controller).to receive(:user_requested_self_search_by_uid?).with(params_uid).and_return(true)
      end

      it do
        expect(controller).to receive(:reject_crawler)
        expect(controller).to receive(:signed_in_user_authorized?)
        expect(controller).to receive(:enough_permission_level?)
        expect(controller).to receive(:valid_uid?).with(params_uid)
        # user_requested_self_search_by_uid? is called
        expect(controller).to receive(:build_twitter_user_by_uid).with(params_uid).and_return(twitter_user)
        expect(controller).to receive(:search_limitation_soft_limited?).with(twitter_user)
        expect(controller).not_to receive(:protected_search?)
        expect(controller).not_to receive(:blocked_search?)
        expect(controller).to receive(:too_many_searches?).with(twitter_user).and_return(false)
        expect(controller).to receive(:too_many_requests?).with(twitter_user).and_return(false)
        subject
      end
    end
  end
end
