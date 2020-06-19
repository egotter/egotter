require 'rails_helper'

RSpec.describe CrawlersHelper, type: :helper do
  describe '#from_crawler?' do
  end

  describe '#from_minor_crawler?' do
    described_class::CRAWLER_WORDS.each do |word|
      context "user_agent is #{word}" do
        let(:user_agent) { word }
        it { is_expected.to be_truthy }
      end
    end
  end
end
