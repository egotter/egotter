require 'rails_helper'

RSpec.describe PromptReport, type: :model do
  let(:user) { create(:user) }
  let(:prompt_report) { PromptReport.new(user_id: user.id, changes_json: {followers_count: [100, 99]}, token: PromptReport.token) }

  describe '.generate_token' do
    it 'generates a unique token' do
      expect(PromptReport.generate_token).to be_truthy
    end
  end
end
