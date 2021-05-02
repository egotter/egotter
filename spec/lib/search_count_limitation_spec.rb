require 'rails_helper'

RSpec.describe SearchCountLimitation, type: :model do
  context 'Constants' do
    it do
      expect(described_class::SIGN_IN_BONUS).to eq(2)
      expect(described_class::SHARING_BONUS).to eq(1)
      expect(described_class::ANONYMOUS).to eq(2)
      expect(described_class::BASIC_PLAN).to eq(10)
    end
  end

  let(:user) { create(:user) }
  let(:session_id) { nil }
  let(:instance) { described_class.new(user: user, session_id: session_id) }

  describe '#max_count' do
    subject { instance.max_count }

    it { is_expected.to eq(described_class::ANONYMOUS + described_class::SIGN_IN_BONUS) }

    context 'user has valid subscription' do
      before do
        allow(user).to receive(:has_valid_subscription?).and_return(true)
        allow(user).to receive(:purchased_search_count).and_return(1)
      end
      it { is_expected.to eq(1) }
    end

    context 'sharing_count is 1' do
      before do
        allow(user).to receive(:sharing_count).and_return(1)
        allow(instance).to receive(:current_sharing_bonus).and_return(2)
      end
      it { is_expected.to eq(described_class::ANONYMOUS + described_class::SIGN_IN_BONUS + 2) }
    end

    context 'coupons_search_count is 1' do
      before do
        allow(user).to receive(:coupons_search_count).and_return(1)
      end
      it { is_expected.to eq(described_class::ANONYMOUS + described_class::SIGN_IN_BONUS + 1) }
    end

    context 'a record of CreatePeriodicTweetRequest exists' do
      before do
        allow(CreatePeriodicTweetRequest).to receive(:exists?).with(user_id: user.id).and_return(true)
      end
      it { is_expected.to eq(described_class::ANONYMOUS + described_class::SIGN_IN_BONUS + described_class::PERIODIC_TWEET_BONUS) }
    end

    context 'user  is not passed' do
      let(:user) { nil }
      it { is_expected.to eq(described_class::ANONYMOUS) }
    end
  end

  describe '#remaining_count' do
    let(:session_id) { 'session_id' }
    subject { instance.remaining_count }

    before do
      allow(instance).to receive(:max_count).and_return(max_count)
      allow(instance).to receive(:current_count).and_return(current_count)
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

  describe '#count_remaining?' do
    subject { instance.count_remaining? }
    before { allow(instance).to receive(:remaining_count).and_return(1) }
    it { is_expected.to be_truthy }
  end

  describe '#where_condition' do
    subject { instance.send(:where_condition) }

    context 'User is passed' do
      let(:user) { instance_double(User, id: 100) }
      let(:session_id) { nil }

      it do
        is_expected.to include(user_id: 100).and include(:created_at)
        is_expected.not_to include(:session_id)
      end
    end

    context 'session_id is passed' do
      let(:user) { nil }
      let(:session_id) { 'session_id' }

      it do
        is_expected.to include(session_id: 'session_id').and include(:created_at)
        is_expected.not_to include(:user_id)
      end
    end
  end

  describe '#current_count' do
    let(:uid) { 1 }
    subject { instance.current_count }

    context 'user is passed' do
      let(:user) { instance_double(User, id: 100) }
      let(:session_id) { nil }

      before do
        create(:search_history, user_id: user.id, session_id: 'aaa', uid: uid)
        create(:search_history, user_id: user.id + 1, session_id: 'bbb', uid: uid)
        create(:search_history, user_id: user.id, session_id: 'ccc', uid: uid)
      end

      it { is_expected.to eq(2) }
    end

    context 'session_id is passed' do
      let(:user) { nil }
      let(:session_id) { 'session_id' }

      before do
        create(:search_history, user_id: -1, session_id: 'aaa', uid: uid)
        create(:search_history, user_id: -1, session_id: 'session_id', uid: uid)
        create(:search_history, user_id: -1, session_id: 'ccc', uid: uid)
      end

      it { is_expected.to eq(1) }
    end
  end

  describe '#count_reset_in' do
    subject { instance.count_reset_in }

    context 'user is passed' do
      let(:user) { instance_double(User, id: 100) }
      let(:session_id) { nil }

      before do
        create(:search_history, user_id: user.id, session_id: 'aaa', uid: 1, created_at: 1.day.ago - 1)
        create(:search_history, user_id: user.id, session_id: 'bbb', uid: 1, created_at: 12.hours.ago)
        create(:search_history, user_id: user.id, session_id: 'ccc', uid: 1, created_at: 1.hour.ago)
      end

      it { is_expected.to be_within(3).of(12.hours.to_i) }
    end
  end

  describe '#current_sharing_bonus' do
    subject { instance.current_sharing_bonus }

    before do
      twitter_user = double('twitter_user', followers_count: count)
      allow(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(twitter_user)
    end

    context 'followers_count is less than or equal to 1000' do
      let(:count) { 1000 }
      it { is_expected.to eq(described_class::SHARING_BONUS) }
    end

    context 'followers_count is less than or equal to 2000' do
      let(:count) { 2000 }
      it { is_expected.to eq(described_class::SHARING_BONUS + 1) }
    end

    context 'followers_count is less than or equal to 5000' do
      let(:count) { 5000 }
      it { is_expected.to eq(described_class::SHARING_BONUS + 2) }
    end

    context 'followers_count is more than 5000' do
      let(:count) { 10000 }
      it { is_expected.to eq(described_class::SHARING_BONUS + 3) }
    end

    context 'An exception is raised' do
      let(:count) { 'count' }
      before { allow(user).to receive(:uid).and_raise('Anything') }
      it { is_expected.to eq(described_class::SHARING_BONUS) }
    end
  end

  describe '#to_h' do
    subject { instance.to_h }
    before do
      allow(instance).to receive(:max_count).and_return('max')
      allow(instance).to receive(:remaining_count).and_return('remaining')
      allow(instance).to receive(:current_count).and_return('current')
      allow(instance).to receive(:current_sharing_bonus).and_return('sharing_bonus')
    end
    it do
      is_expected.to eq(user_id: user.id, max: 'max', remaining: 'remaining', current: 'current', sharing_bonus: 'sharing_bonus', sharing_count: 0)
    end
  end
end
