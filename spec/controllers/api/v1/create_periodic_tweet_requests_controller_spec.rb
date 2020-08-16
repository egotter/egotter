require 'rails_helper'

RSpec.describe Api::V1::CreatePeriodicTweetRequestsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:user_signed_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #update' do
    it do
      expect(controller).to receive(:reject_crawler)
      expect(controller).to receive(:require_login!).and_call_original
      post :update, params: {value: 'true'}
    end

    context 'value is not set' do
      it do
        post :update
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'value is true' do
      it do
        expect(controller).to receive(:create_record).with(user)
        post :update, params: {value: 'true'}
      end
    end

    context 'value is false' do
      it do
        expect(controller).to receive(:destroy_record).with(user)
        post :update, params: {value: 'false'}
      end
    end
  end
end
