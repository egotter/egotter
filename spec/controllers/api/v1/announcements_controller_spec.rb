require 'rails_helper'

RSpec.describe Api::V1::AnnouncementsController, type: :controller do
  before { 15.times { create(:announcement) } }

  describe 'GET #list' do
    it do
      get :list
      expect(JSON.parse(response.body).has_key?('html')).to be_truthy
    end
  end
end
