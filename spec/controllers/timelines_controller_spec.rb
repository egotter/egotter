require 'rails_helper'

RSpec.describe TimelinesController, type: :controller do
  describe 'GET #show' do
    let(:screen_name) { 'name' }

    it do
      expect(controller).to receive(:validate_screen_name!)
      expect(controller).to receive(:find_or_create_search_request)
      get :show, params: {screen_name: screen_name}
    end
  end
end
