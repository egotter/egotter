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

  describe '#inactive_label' do
    subject { decorator.inactive_label }
    before { allow(decorator).to receive(:inactive?).and_return(true) }
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
    before { allow(decorator).to receive(:protected?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#verified_icon' do
    subject { decorator.verified_icon }
    before { allow(decorator).to receive(:verified?).and_return(true) }
    it { is_expected.to be_truthy }
  end
end
