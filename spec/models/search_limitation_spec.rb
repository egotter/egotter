require 'rails_helper'

RSpec.describe SearchLimitation, type: :model do
  describe '.limited?' do
    let(:user) { double('User') }
    subject { described_class.limited?(user, signed_in: signed_in) }

    context 'signed_in == false' do
      let(:signed_in) { false }
      it do
        expect(described_class).to receive(:soft_limited?).with(user)
        subject
      end
    end

    context 'signed_in == true' do
      let(:signed_in) { true }
      it do
        expect(described_class).to receive(:hard_limited?).with(user)
        subject
      end
    end
  end

  describe '.soft_limited?' do
    let(:twitter_user) { build(:twitter_user, friends_count: friends_count, followers_count: followers_count, with_relations: false) }
    subject { described_class.soft_limited?(twitter_user) }

    context 'friends_count + followers_count > 2000' do
      let(:friends_count) { 1000 }
      let(:followers_count) { 1001 }
      it { expect(friends_count + followers_count).to be > SearchLimitation::SOFT_LIMIT }
      it { is_expected.to be_truthy }
    end

    context 'friends_count + followers_count <= 2000' do
      let(:friends_count) { 1000 }
      let(:followers_count) { 1000 }
      it { expect(friends_count + followers_count).to be <= SearchLimitation::SOFT_LIMIT }
      it { is_expected.to be_falsey }
    end
  end

  describe '.hard_limited?' do
    let(:twitter_user) { build(:twitter_user, friends_count: friends_count, followers_count: followers_count, with_relations: false) }
    subject { described_class.hard_limited?(twitter_user) }

    context 'friends_count + followers_count > 60000' do
      let(:friends_count) { 30000 }
      let(:followers_count) { 30001 }
      it { expect(friends_count + followers_count).to be > SearchLimitation::HARD_LIMIT }
      it { is_expected.to be_truthy }
    end

    context 'friends_count + followers_count <= 60000' do
      let(:friends_count) { 30000 }
      let(:followers_count) { 30000 }
      it { expect(friends_count + followers_count).to be <= SearchLimitation::HARD_LIMIT }
      it { is_expected.to be_falsey }
    end
  end
end
