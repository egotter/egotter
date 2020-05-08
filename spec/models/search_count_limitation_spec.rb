require 'rails_helper'

RSpec.describe SearchCountLimitation, type: :model do
  context 'Constants' do
    it do
      expect(described_class::SIGN_IN_BONUS).to eq(3)
      expect(described_class::SHARING_BONUS).to eq(2)
      expect(described_class::ANONYMOUS).to eq(2)
      expect(described_class::BASIC_PLAN).to eq(10)
    end
  end

  describe '.max_search_count' do
    subject { SearchCountLimitation.max_search_count(user) }

    context 'User is passed' do
      let(:user) { instance_double(User) }

      context 'user#has_valid_subscription? == false' do
        before do
          allow(user).to receive(:has_valid_subscription?).with(no_args).and_return(false)
          allow(user).to receive(:sharing_count).with(no_args).and_return(0)
        end
        it { is_expected.to eq(described_class::ANONYMOUS + described_class::SIGN_IN_BONUS) }
      end

      context 'user#has_valid_subscription? == true' do
        before do
          allow(user).to receive(:has_valid_subscription?).with(no_args).and_return(true)
          allow(user).to receive(:purchased_search_count).with(no_args).and_return(100)
          allow(user).to receive(:sharing_count).with(no_args).and_return(0)
        end
        it { is_expected.to eq(100) }
      end

      context 'user#sharing_count == 2' do
        before do
          allow(user).to receive(:has_valid_subscription?).with(no_args).and_return(false)
          allow(user).to receive(:sharing_count).with(no_args).and_return(2)
          allow(described_class).to receive(:current_sharing_bonus).with(user).and_return(99)
        end
        it { is_expected.to eq(described_class::ANONYMOUS + described_class::SIGN_IN_BONUS + 2 * 99) }
      end
    end

    context 'nil is passed' do
      let(:user) { nil }
      it { is_expected.to eq(described_class::ANONYMOUS) }
    end
  end

  describe '.remaining_search_count' do
    let(:user) { instance_double(User) }
    let(:session_id) { 'session_id' }
    subject { described_class.remaining_search_count(user: user, session_id: session_id) }

    before do
      allow(described_class).to receive(:max_search_count).with(user).and_return(max_count)
      allow(described_class).to receive(:current_search_count).with(user: user, session_id: session_id).and_return(current_count)
    end

    context 'max_search_count > current_search_count' do
      let(:max_count) { 10 }
      let(:current_count) { 8 }
      it { is_expected.to eq(2) }
    end

    context 'max_search_count < current_search_count' do
      let(:max_count) { 10 }
      let(:current_count) { 12 }
      it { is_expected.to eq(0) }
    end

    context 'max_search_count == current_search_count' do
      let(:max_count) { 10 }
      let(:current_count) { 10 }
      it { is_expected.to eq(0) }
    end
  end

  describe '.where_condition' do
    subject { described_class.where_condition(user: user, session_id: session_id) }

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

  describe '.current_search_count' do
    let(:uid) { 1 }
    subject { described_class.current_search_count(user: user, session_id: session_id) }

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

  describe '.search_count_reset_in' do
    subject { described_class.search_count_reset_in(user: user, session_id: session_id) }

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
    let(:user) { create(:user) }
    subject { described_class.current_sharing_bonus(user) }

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
end
