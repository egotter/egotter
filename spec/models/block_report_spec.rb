require 'rails_helper'

RSpec.describe BlockReport, type: :model do
  let(:user) { create(:user) }

  describe '#you_are_blocked' do
    subject { described_class.you_are_blocked(user.id, [{uid: 1, screen_name: 'name'}]) }
    it { is_expected.to be_truthy }
  end
end
