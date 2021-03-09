require 'rails_helper'

RSpec.describe PrivateModeSetting, type: :model do
  describe '.specified?' do
    let(:user) { create(:user) }
    subject { described_class.specified?(user.uid) }

    context 'private-mode is specified' do
      before { described_class.create!(user_id: user.id) }
      it { is_expected.to be_truthy }
    end

    context 'private-mode is NOT specified' do
      it { is_expected.to be_falsey }
    end
  end
end
