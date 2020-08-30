require 'rails_helper'

RSpec.describe WordCloud, type: :model do
  let(:instance) { described_class.new }

  describe '.mecab_model' do
    subject { described_class.mecab_model }
    it { is_expected.to be_truthy }
  end

  describe '#mecab_tagger' do
    subject { instance.send(:mecab_tagger) }
    it { is_expected.to be_truthy }
  end

  describe '#truncate_text' do
    let(:text) { 'a' * 1.megabyte }
    subject { instance.send(:truncate_text, text) }
    it { expect(subject.bytesize).to be < 900.kilobytes }
  end
end
