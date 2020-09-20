require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe '.list' do
    subject { described_class.list }

    before do
      date = Time.zone.now.in_time_zone('Tokyo').to_date.strftime('%Y/%m/%d')
      15.times do |n|
        described_class.create!(date: date, message: "text #{n}")
      end
    end

    it { expect(subject.size).to eq(12) }
  end
end
