require 'rails_helper'

RSpec.describe UsageStat, type: :model do
  let(:uid) { rand(1000) }
  let(:statuses) { [build(:mention_status)] }

  describe '.builder' do
    it 'returns an instance of UsageStat::Builder' do
      expect(UsageStat.builder(uid)).to be_an_instance_of(UsageStat::Builder)
    end
  end
end

RSpec.describe UsageStat::Builder, type: :model do
end

RSpec.describe UsageStat::WordCloud, type: :model do
  let(:instance) { described_class.new }

  describe '#truncate_text' do
    let(:text) { 'a' * 1.megabyte }
    subject { instance.send(:truncate_text, text) }
    it { expect(subject.bytesize).to be < 900.kilobytes }
  end
end
