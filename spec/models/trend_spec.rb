require 'rails_helper'

RSpec.describe Trend, type: :model do
  describe '.fetch_trends' do
    let(:raw_trends) { 2.times.map { double('trend', name: 'name', query: 'query', tweet_volume: 1, promoted_content?: false) } }
    subject { described_class.fetch_trends }
    before do
      allow(User).to receive_message_chain(:admin, :api_client, :twitter, :trends).
          with(described_class::WORLD_WOE_ID).and_return(raw_trends)

      allow(User).to receive_message_chain(:admin, :api_client, :twitter, :trends).
          with(described_class::JAPAN_WOE_ID).and_return(raw_trends)
    end
    it { is_expected.to be_truthy }
  end
end
