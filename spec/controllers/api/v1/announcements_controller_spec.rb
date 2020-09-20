require 'rails_helper'

RSpec.describe Api::V1::AnnouncementsController, type: :controller do
  before { 15.times { create(:announcement) } }

  describe 'GET #list' do
    it do
      get :list
      JSON.parse(response.body)['records'].each do |record|
        expect(record.has_key?('date')).to be_truthy
        expect(record.has_key?('message')).to be_truthy
      end
    end
  end
end
