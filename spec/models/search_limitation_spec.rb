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
    let(:user) { double('User') }
    subject { described_class.soft_limited?(user) }

    before do
      allow(user).to receive(:[]).with(:friends_count).and_return(friends_count)
      allow(user).to receive(:[]).with(:followers_count).and_return(followers_count)
    end

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
    let(:user) { double('User') }
    subject { described_class.hard_limited?(user) }

    before do
      allow(user).to receive(:[]).with(:friends_count).and_return(friends_count)
      allow(user).to receive(:[]).with(:followers_count).and_return(followers_count)
    end

    context 'friends_count + followers_count > 15000' do
      let(:friends_count) { 7500 }
      let(:followers_count) { 7501 }
      it { expect(friends_count + followers_count).to be > SearchLimitation::HARD_LIMIT }
      it { is_expected.to be_truthy }
    end

    context 'friends_count + followers_count <= 15000' do
      let(:friends_count) { 7500 }
      let(:followers_count) { 7500 }
      it { expect(friends_count + followers_count).to be <= SearchLimitation::HARD_LIMIT }
      it { is_expected.to be_falsey }
    end
  end
end
