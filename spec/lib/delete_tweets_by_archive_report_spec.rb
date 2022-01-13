require 'rails_helper'

RSpec.describe DeleteTweetsByArchiveReport, type: :model do
  let(:user) { create(:user) }

  describe '.delete_completed' do
    subject { described_class.delete_completed(user, 1) }
    it { is_expected.to be_truthy }
  end

  describe '.no_tweet_found' do
    subject { described_class.no_tweet_found(user) }
    it { is_expected.to be_truthy }
  end
end
