require 'rails_helper'

RSpec.describe CrawlersHelper, type: :helper do
  describe '#from_crawler?' do
  end

  describe '#from_minor_crawler?' do
    subject { helper.send(:from_minor_crawler?, user_agent) }

    described_class::CRAWLER_WORDS.each do |word|
      context "user_agent includes #{word}" do
        let(:user_agent) { word }
        it { is_expected.to be_truthy }
      end
    end

    described_class::CRAWLER_FULL_NAMES.each do |name|
      context "user_agent is #{name}" do
        let(:user_agent) { name }
        it { is_expected.to be_truthy }
      end

      context "user_agent is #{name + ' + suffix'}" do
        let(:user_agent) { name + ' + suffix' }
        it { is_expected.to be_falsey }
      end
    end
  end
end
