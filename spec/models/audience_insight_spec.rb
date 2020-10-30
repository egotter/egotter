require 'rails_helper'

RSpec.describe AudienceInsight do
end

RSpec.describe AudienceInsight::Builder do
  describe '#build' do
    let(:twitter_user) { create(:twitter_user) }
    subject { described_class.new(twitter_user.uid).build }
    before do
      allow(TwitterUser).to receive_message_chain(:latest_by, :status_tweets).
          with(uid: twitter_user.uid).with(no_args).and_return([])
    end
    it { is_expected.to be_truthy }
  end
end
