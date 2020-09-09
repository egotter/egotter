require 'rails_helper'

RSpec.describe WordCloud, type: :model do
  let(:instance) { described_class.new }

  describe '#truncate_text' do
    let(:text) { 'a' * 1.megabyte }
    subject { instance.send(:truncate_text, text) }
    it { expect(subject.bytesize).to be < 900.kilobytes }
  end
end
