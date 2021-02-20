require 'rails_helper'

RSpec.describe TrendInsight, type: :model do
  describe '.calc_words_count' do
    let(:tweets) { [double('tweet', text: 'りんご ばなな ばなな ばなな')] }
    subject { described_class.calc_words_count(tweets) }
    it { is_expected.to eq([['ばなな', 3]]) }
  end
end
