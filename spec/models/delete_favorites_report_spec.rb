require 'rails_helper'

RSpec.describe DeleteFavoritesReport, type: :model do
  let(:user) { create(:user) }
  let(:request) { DeleteFavoritesRequest.create(user: user, destroy_count: 0) }

  describe '.finished_tweet' do
    subject { described_class.finished_tweet(user, request) }
    it { is_expected.to be_truthy }
  end

  describe '.finished_message' do
    subject { described_class.finished_message(user, request) }
    it { is_expected.to be_truthy }

    context 'destroy_count is 10' do
      before { request.update!(destroy_count: 10) }
      it { is_expected.to be_truthy }
    end
  end

  describe '.finished_message_from_user' do
    subject { described_class.finished_message_from_user(user) }
    it { is_expected.to be_truthy }
  end

  describe '.error_message' do
    subject { described_class.error_message(user) }
    it { is_expected.to be_truthy }
  end

  describe '.delete_favorites_url' do
    subject { described_class.delete_favorites_url('via') }
    it { is_expected.to be_truthy }
  end

  describe '#delete_favorites_url' do
    subject { described_class.delete_favorites_url('via') }
    it { is_expected.to be_truthy }
  end

  describe '#delete_favorites_mypage_url' do
    subject { described_class.delete_favorites_mypage_url('via') }
    it { is_expected.to be_truthy }
  end
end
