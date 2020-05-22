require 'rails_helper'

RSpec.describe TwitterDB::User, type: :model do
  context 'association' do
    let(:users) { 3.times.map { create(:twitter_db_user) } }
    let(:rest_users) { users - [users[0]] }
  end

  describe '#inactive?' do
    let(:user) { create(:twitter_db_user, status_created_at: time) }
    subject { user.inactive? }

    context 'status_created_at is nil' do
      let(:time) { nil }
      it { is_expected.to be_falsey }
    end

    context 'status_created_at is 1.month.ago' do
      let(:time) { 1.month.ago }
      it { is_expected.to be_truthy }
    end

    context 'status_created_at is 1.day.ago' do
      let(:time) { 1.day.ago }
      it { is_expected.to be_falsey }
    end
  end

  describe '.inactive_user' do
    let!(:user) { create(:twitter_db_user, status_created_at: time) }
    subject { TwitterDB::User.inactive_user }

    context 'status_created_at is nil' do
      let(:time) { nil }
      it { is_expected.to satisfy { |result| result.empty? } }
    end

    context 'status_created_at is 1.month.ago' do
      let(:time) { 1.month.ago }
      it { is_expected.to satisfy { |result| result.size == 1 && result.first.id == user.id } }
    end

    context 'status_created_at is 1.day.ago' do
      let(:time) { 1.day.ago }
      it { is_expected.to satisfy { |result| result.empty? } }
    end
  end

  describe '.import_by!' do
    let(:t_users) { 3.times.map { build(:t_user) } }
    subject { TwitterDB::User.import_by!(users: t_users) }
    it { expect { subject }.to change { TwitterDB::User.all.size }.by(t_users.size) }
  end
end

RSpec.describe TwitterDB::User::Batch, type: :model do
  describe '.import' do
    let(:users) { 3.times.map { build(:t_user) } }

    context 'There are 3 new records' do
      it 'imports all records' do
        expect { TwitterDB::User::Batch.import(users) }.to change { TwitterDB::User.all.size }.by(users.size)
      end
    end

    context 'There are 2 new records and 1 persisted record' do
      before { TwitterDB::User.create!(uid: users[0][:id], screen_name: users[0][:screen_name]) }
      it 'imports only new records' do
        expect { TwitterDB::User::Batch.import(users) }.to change { TwitterDB::User.all.size }.by(users.size - 1)
      end
    end

    context 'There are 3 persisted records' do
      let(:time) { (TwitterDB::User::Batch::UPDATE_RECORD_INTERVAL - 1.second).ago.round }
      before do
        users.each do |user|
          TwitterDB::User.create!(uid: user[:id], screen_name: user[:screen_name], created_at: time, updated_at: time)
        end
      end

      context 'force_update == true' do
        it 'imports all records' do
          freeze_time do
            TwitterDB::User::Batch.import(users, force_update: true)
            users.each do |user|
              expect(TwitterDB::User.find_by(uid: user[:id]).updated_at).to eq(Time.zone.now.round)
            end
          end
        end
      end

      context 'force_update == false' do
        it "doesn't import any records" do
          TwitterDB::User::Batch.import(users, force_update: false)
          users.each do |user|
            expect(TwitterDB::User.find_by(uid: user[:id]).updated_at).to eq(time)
          end
        end
      end
    end
  end
end
