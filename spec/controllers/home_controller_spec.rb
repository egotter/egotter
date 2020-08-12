require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #new' do
    it do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #start' do
    it do
      get :start
      expect(response).to have_http_status(:ok)
    end
  end
end
