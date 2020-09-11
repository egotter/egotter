require 'rails_helper'

RSpec.describe TwitterDBUserBatch, type: :model do
  describe '.import' do
    let(:users) { 3.times.map { build(:t_user) } }

    context 'There are 3 new records' do
      it 'imports all records' do
        expect { described_class.import(users) }.to change { TwitterDB::User.all.size }.by(users.size)
      end
    end

    context 'There are 2 new records and 1 persisted record' do
      before { TwitterDB::User.create!(uid: users[0][:id], screen_name: users[0][:screen_name]) }
      it 'imports only new records' do
        expect { described_class.import(users) }.to change { TwitterDB::User.all.size }.by(users.size - 1)
      end
    end

    context 'There are 3 persisted records' do
      let(:time) { (described_class::UPDATE_RECORD_INTERVAL - 1.second).ago.round }
      before do
        users.each do |user|
          TwitterDB::User.create!(uid: user[:id], screen_name: user[:screen_name], created_at: time, updated_at: time)
        end
      end

      context 'force_update == true' do
        it 'imports all records' do
          freeze_time do
            described_class.import(users, force_update: true)
            users.each do |user|
              expect(TwitterDB::User.find_by(uid: user[:id]).updated_at).to eq(Time.zone.now.round)
            end
          end
        end
      end

      context 'force_update == false' do
        it "doesn't import any records" do
          described_class.import(users, force_update: false)
          users.each do |user|
            expect(TwitterDB::User.find_by(uid: user[:id]).updated_at).to eq(time)
          end
        end
      end
    end
  end
end

