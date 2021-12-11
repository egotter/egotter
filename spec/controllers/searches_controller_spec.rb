require 'rails_helper'

RSpec.describe SearchesController, type: :controller do
  describe 'POST #create' do
    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    let(:screen_name) { twitter_user.screen_name }
    subject { post :create, params: {screen_name: screen_name} }

    it do
      expect(controller).to receive(:validate_screen_name!)
      expect(controller).to receive(:find_or_create_search_request)
      subject
    end
  end
end
