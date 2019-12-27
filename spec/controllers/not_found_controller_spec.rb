require 'rails_helper'

RSpec.describe NotFoundController, type: :controller do
  let(:screen_name) { 'sn' }
  let(:twitter_db_user) { create(:twitter_user, screen_name: screen_name) }

  before do
    allow(TwitterDB::User).to receive(:find_by).with(screen_name: screen_name).and_return(twitter_db_user)
  end

  describe 'GET #show' do
    subject { get :show, params: {screen_name: screen_name} }

    context 'The visitor is twitter crawler' do
      before { allow(controller).to receive(:twitter_crawler?).and_return(true) }
      it do
        expect(NotFoundUser).not_to receive(:exists?)
        expect(controller).not_to receive(:not_found_user?)
        is_expected.to have_http_status(:success)
      end
    end

    context 'The visitor is NOT twitter crawler' do
      before { allow(controller).to receive(:twitter_crawler?).and_return(false) }
      it do
        expect(NotFoundUser).to receive(:exists?).with(screen_name: screen_name).and_return(true)
        is_expected.to have_http_status(:success)
      end
    end
  end
end
