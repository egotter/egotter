require 'rails_helper'

RSpec.describe SearchReport, type: :model do
  let(:user) { create(:user) }
  let(:search_report) { SearchReport.new(user_id: user.id, changes_json: {followers_count: [100, 99]}, token: SearchReport.token) }

  describe '.generate_token' do
    it 'generates a unique token' do
      expect(SearchReport.generate_token).to be_truthy
    end
  end
end
