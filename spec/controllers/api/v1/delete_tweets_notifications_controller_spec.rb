require 'rails_helper'

RSpec.describe Api::V1::DeleteTweetsNotificationsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    subject { post :create, params: {} }
    it { is_expected.to have_http_status(:ok) }
  end
end
