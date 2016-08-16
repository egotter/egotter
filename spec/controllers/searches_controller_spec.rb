require 'rails_helper'

RSpec.describe SearchesController, type: :controller do

  describe 'GET #new' do
    it 'calls create_search_log' do
      expect(controller).to receive(:create_search_log)
      get :new
    end
  end

end
