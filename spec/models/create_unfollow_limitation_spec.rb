require 'rails_helper'

RSpec.describe CreateUnfollowLimitation, type: :model do
  context 'Constants' do
    it do
      expect(described_class::ANONYMOUS).to eq(2)
      expect(described_class::BASIC_PLAN).to eq(20)
    end
  end

  describe '.max_count' do
    subject { described_class.max_count(user) }

    context 'User is passed' do
      let(:user) { instance_double(User, uid: 1) }

      before { allow(user).to receive(:has_valid_subscription?).with(no_args).and_return(value) }

      context 'user#has_valid_subscription? == false' do
        let(:value) { false }
        it { is_expected.to eq(described_class::ANONYMOUS) }
      end

      context 'user#has_valid_subscription? == true' do
        let(:value) { true }
        it { is_expected.to eq(20) }
      end
    end

    context 'nil is passed' do
      let(:user) { nil }
      it { is_expected.to eq(described_class::ANONYMOUS) }
    end
  end

  describe '.remaining_count' do
    let(:user) { instance_double(User) }
    subject { described_class.remaining_count(user) }

    before do
      allow(described_class).to receive(:max_count).with(user).and_return(max_count)
      allow(described_class).to receive(:current_count).with(user).and_return(current_count)
    end

    context 'max_count > current_count' do
      let(:max_count) { 10 }
      let(:current_count) { 8 }
      it { is_expected.to eq(2) }
    end

    context 'max_count < current_count' do
      let(:max_count) { 10 }
      let(:current_count) { 12 }
      it { is_expected.to eq(0) }
    end

    context 'max_count == current_count' do
      let(:max_count) { 10 }
      let(:current_count) { 10 }
      it { is_expected.to eq(0) }
    end
  end

  describe '.unfollow_requests' do
    let(:user) { create(:user) }
    let!(:request1) { user.unfollow_requests.create!(uid: 1, created_at: 2.hour.ago) }
    let!(:request2) { user.unfollow_requests.create!(uid: 2, created_at: 1.hour.ago) }
    let!(:request3) { user.unfollow_requests.create!(uid: User::EGOTTER_UID) }
    subject { described_class.unfollow_requests(user) }
    it { is_expected.to match_array([request1, request2, request3]) }
  end

  describe '.current_count' do
    let(:user) { instance_double(User) }
    subject { described_class.current_count(user) }
    before { allow(described_class).to receive(:unfollow_requests).with(user).and_return([1, 2, 3]) }
    it { is_expected.to eq(3) }
  end

  describe '.count_reset_in' do
    let(:user) { create(:user) }
    subject { described_class.count_reset_in(user) }

    before do
      request = user.unfollow_requests.create!(uid: 1, created_at: 1.hour.ago)
      allow(described_class).to receive(:unfollow_requests).with(user).and_return([request])
    end

    it { is_expected.to be_within(3).of(23.hours.to_i) }
  end
end
