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