require 'rails_helper'

RSpec.describe Concerns::Visitor::Activeness do
  describe '.active_access' do
    subject { User.active_access(10) }
    it do
      freeze_time do
        expect(User).to receive(:where).with('last_access_at > ?', 10.days.ago)
        subject
      end
    end
  end

  describe '#active_access?' do
    let(:user) { create(:user, last_access_at: last_access_at) }
    subject { user.active_access?(10) }

    context 'last_access_at is nil' do
      let(:last_access_at) { nil }
      it { is_expected.to be_nil }
    end

    context 'last_access_at is 1.day ago'
    let(:last_access_at) { 1.day.ago }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_access?' do
    let(:user) { create(:user) }
    subject { user.inactive_access?(10) }

    it do
      expect(user).to receive(:active_access?).with(10).and_return(false)
      is_expected.to be_truthy
    end
  end
end