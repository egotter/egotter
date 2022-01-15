require 'rails_helper'

RSpec.describe DeleteTweetsReport, type: :model do
  let(:user) { create(:user, authorized: true) }
  let(:request) { DeleteTweetsRequest.create(user: user, destroy_count: 0) }

  describe '.finished_tweet' do
    subject { described_class.finished_tweet(user, request) }
    before { request.update(started_at: 10.seconds.ago, finished_at: 10.seconds.since) }
    it { is_expected.to be_truthy }
  end

  describe '.finished_message' do
    subject { described_class.finished_message(user, deletions_count) }
    [0, 10].each do |count|
      let(:deletions_count) { count }
      context "deletions_count is #{count}" do
        it { is_expected.to be_truthy }
      end
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

  describe '.delete_tweets_url' do
    subject { described_class.delete_tweets_url('via') }
    it { is_expected.to be_truthy }
  end

  describe '#delete_tweets_url' do
    subject { described_class.delete_tweets_url('via') }
    it { is_expected.to be_truthy }
  end

  describe '#delete_tweets_mypage_url' do
    subject { described_class.delete_tweets_mypage_url('via') }
    it { is_expected.to be_truthy }
  end
end
