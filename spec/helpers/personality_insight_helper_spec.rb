require 'rails_helper'

RSpec.describe PersonalityInsightsHelper, type: :helper do
  describe '#personality_insight_score_details' do
    context 'percentile is 0.60' do
      let(:trait) { {'raw_score' => 0.10, 'percentile' => 0.60} }
      subject { personality_insight_score_details(trait) }
      it { is_expected.not_to include('1%未満') }
    end

    context 'percentile is less than 0.01' do
      let(:trait) { {'raw_score' => 0.10, 'percentile' => 0.0025} }
      subject { personality_insight_score_details(trait) }
      it { is_expected.to include('1%未満') }
    end

    context 'percentile is greater than 0.99' do
      let(:trait) { {'raw_score' => 0.10, 'percentile' => 0.995} }
      subject { personality_insight_score_details(trait) }
      it { is_expected.to include('1%未満') }
    end
  end
end
