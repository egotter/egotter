require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  before do
    allow(helper).to receive(:current_user)
  end

  describe '#current_user_icon' do
    subject { helper.current_user_icon }
    before { allow(helper).to receive(:user_signed_in?) }
    it { is_expected.to be_truthy }
  end

  describe '#current_user_statuses_count' do
    subject { helper.current_user_statuses_count }
    it { is_expected.to be_falsey }
  end
end
