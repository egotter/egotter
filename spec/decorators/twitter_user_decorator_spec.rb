require 'rails_helper'

RSpec.describe TwitterUserDecorator do
  let(:twitter_user) { build(:twitter_user) }
  let(:decorator) { TwitterUserDecorator.new(twitter_user) }

  describe '#suspended_label' do
    subject { decorator.suspended_label }
    before { allow(decorator).to receive(:suspended?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#blocked_label' do
    subject { decorator.blocked_label }
    before { allow(decorator).to receive(:blocked?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_2weeks_label' do
    subject { decorator.inactive_2weeks_label }
    before { allow(decorator).to receive(:inactive_2weeks?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_1month_label' do
    subject { decorator.inactive_1month_label }
    before { allow(decorator).to receive(:inactive_1month?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_3months_label' do
    subject { decorator.inactive_3months_label }
    before { allow(decorator).to receive(:inactive_3months?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_6months_label' do
    subject { decorator.inactive_6months_label }
    before { allow(decorator).to receive(:inactive_6months?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_1year_label' do
    subject { decorator.inactive_1year_label }
    before { allow(decorator).to receive(:inactive_1year?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#refollow_label' do
    subject { decorator.refollow_label }
    before { allow(decorator).to receive(:refollow?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#refollowed_label' do
    subject { decorator.refollowed_label }
    before { allow(decorator).to receive(:refollowed?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#followed_label' do
    subject { decorator.followed_label }
    it { is_expected.to be_truthy }
  end

  describe '#protected_icon' do
    subject { decorator.protected_icon }
    before { allow(decorator).to receive(:protected_account?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#verified_icon' do
    subject { decorator.verified_icon }
    before { allow(decorator).to receive(:verified_account?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#active?' do
    subject { decorator.active? }
    before { allow(decorator).to receive(:inactive_2weeks?).and_return(false) }
    it { is_expected.to be_truthy }
  end

  describe '#inactive_2weeks?' do
    subject { decorator.inactive_2weeks? }
    it do
      expect(decorator).to receive(:inactive_period?).with(2.weeks).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#inactive_1month?' do
    subject { decorator.inactive_1month? }
    it do
      expect(decorator).to receive(:inactive_period?).with(1.month).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#inactive_3months?' do
    subject { decorator.inactive_3months? }
    it do
      expect(decorator).to receive(:inactive_period?).with(3.months).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#inactive_6months?' do
    subject { decorator.inactive_6months? }
    it do
      expect(decorator).to receive(:inactive_period?).with(6.months).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#inactive_1year?' do
    subject { decorator.inactive_1year? }
    it do
      expect(decorator).to receive(:inactive_period?).with(1.year).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#inactive_period?' do
    subject { decorator.send(:inactive_period?, duration) }
    before { allow(twitter_user).to receive(:status_created_at).and_return(3.weeks.ago) }

    context 'duration is 2 weeks' do
      let(:duration) { 2.weeks }
      it { is_expected.to be_truthy }
    end

    context 'duration is 1 month' do
      let(:duration) { 1.month }
      it { is_expected.to be_falsey }
    end
  end
end
