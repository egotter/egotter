require 'rails_helper'

RSpec.describe UsageStat, type: :model do
  let(:uid) { rand(1000) }
  let(:statuses) { [build(:mention_status)] }

  describe '.builder' do
    it 'returns an instance of UsageStat::Builder' do
      expect(UsageStat.builder(uid)).to be_an_instance_of(UsageStat::Builder)
    end
  end

  describe '#most_active_hour' do
    let(:times) { [1.hours.ago.to_i, 2.hours.ago.to_i, 2.hours.ago.to_i, 3.hours.ago.to_i] }
    let(:instance) { build(:usage_stat, tweet_times: times) }
    subject { instance.most_active_hour }
    it { is_expected.to eq(Time.zone.at(times[1]).hour) }
  end

  describe '#most_active_wday' do
    let(:times) { [1.days.ago.to_i, 2.days.ago.to_i, 2.days.ago.to_i, 3.days.ago.to_i] }
    let(:instance) { build(:usage_stat, tweet_times: times) }
    subject { instance.most_active_wday }
    it { is_expected.to eq(I18n.t('date.abbr_day_names')[Time.zone.at(times[1]).wday]) }
  end
end

RSpec.describe UsageStat::Builder, type: :model do
end
