require 'rails_helper'

RSpec.describe FriendsCountPointsUtil, type: :model do
  let(:klass) { FriendsCountPoint }

  describe '#group_by_day' do
    let(:uid) { 1 }
    let(:end_time) { Time.zone.now }
    subject { klass.group_by_day(uid, start_time, end_time, true) }

    context 'complete data' do
      let(:start_time) { 2.days.ago }
      before do
        klass.create!(uid: uid, value: 100, created_at: 2.days.ago)
        klass.create!(uid: uid, value: 200, created_at: 1.days.ago)
        klass.create!(uid: uid, value: 300, created_at: Time.zone.now)
      end
      it do
        data = subject

        expect(data.size).to eq(3)
        expect(data[0].val.to_i).to eq(100)
        expect(data[1].val.to_i).to eq(200)
        expect(data[2].val.to_i).to eq(300)
      end
    end

    context 'first data is missing' do
      let(:start_time) { 2.days.ago }
      before do
        klass.create!(uid: uid, value: 100, created_at: 1.days.ago)
        klass.create!(uid: uid, value: 200, created_at: Time.zone.now)
      end
      it do
        data = subject
        expect(data.size).to eq(3)
        expect(data[0].val.to_i).to eq(100)
        expect(data[1].val.to_i).to eq(100)
        expect(data[2].val.to_i).to eq(200)
      end
    end

    context 'in-between data is missing' do
      let(:start_time) { 2.days.ago }
      before do
        klass.create!(uid: uid, value: 100, created_at: 2.days.ago)
        klass.create!(uid: uid, value: 200, created_at: Time.zone.now)
      end
      it do
        data = subject
        expect(data.size).to eq(3)
        expect(data[0].val.to_i).to eq(100)
        expect(data[1].val.to_i).to eq(150)
        expect(data[2].val.to_i).to eq(200)
      end
    end

    context 'last data is missing' do
      let(:start_time) { 2.days.ago }
      before do
        klass.create!(uid: uid, value: 100, created_at: 2.days.ago)
        klass.create!(uid: uid, value: 200, created_at: 1.days.ago)
      end
      it do
        data = subject
        expect(data.size).to eq(3)
        expect(data[0].val.to_i).to eq(100)
        expect(data[1].val.to_i).to eq(200)
        expect(data[2].val.to_i).to eq(200)
      end
    end
  end
end
