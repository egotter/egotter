require 'rails_helper'

RSpec.describe TimelinesController, type: :controller do
  describe 'GET #show' do
    let(:twitter_user) { build(:twitter_user) }
    let(:screen_name) { twitter_user.screen_name }
    subject { get :show, params: {screen_name: screen_name} }

    it do
      expect(controller).to receive(:valid_screen_name?)
      expect(controller).to receive(:not_found_screen_name?)
      expect(controller).to receive(:forbidden_screen_name?)
      expect(controller).to receive(:find_or_create_search_request)
      subject
    end
  end
end
