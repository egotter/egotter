require 'rails_helper'

RSpec.describe TwitterDB::User, type: :model do
  context 'association' do
    let(:users) { 3.times.map { create(:twitter_db_user) } }
    let(:rest_users) { users - [users[0]] }
  end

  describe '#statuses' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index { |i| create(:twitter_db_status, uid: user.uid, screen_name: user.screen_name, sequence: i) } }
    it 'has many statuses' do
      expect(user.statuses.size).to eq(3)
    end
  end

  describe '#favorites' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index { |i| create(:twitter_db_favorite, uid: user.uid, screen_name: user.screen_name, sequence: i) } }
    it 'has many favorites' do
      expect(user.favorites.size).to eq(3)
    end
  end

  describe '#mentions' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index { |i| create(:twitter_db_mention, uid: user.uid, screen_name: user.screen_name, sequence: i) } }
    it 'has many mentions' do
      expect(user.mentions.size).to eq(3)
    end
  end

  describe '#inactive?' do
    context 'status_created_at is nil' do
      let(:user) { create(:twitter_db_user, status_created_at: nil) }
      it do
        expect(user.inactive?).to be_falsey
      end
    end

    context 'status_created_at is 1.month.ago' do
      let(:user) { create(:twitter_db_user, status_created_at: 1.month.ago) }
      it do
        expect(user.inactive?).to be_truthy
      end
    end

    context 'status_created_at is 1.day.ago' do
      let(:user) { create(:twitter_db_user, status_created_at: 1.day.ago) }
      it do
        expect(user.inactive?).to be_falsey
      end
    end
  end

  describe '.build_by' do
    let(:t_user) { build(:t_user) }
    let(:user) { TwitterDB::User.build_by(user: t_user) }

    it do
      expect(user.screen_name).to eq(t_user[:screen_name])
      expect(user.friends_count).to eq(t_user[:friends_count])
      expect(user.followers_count).to eq(t_user[:followers_count])
      expect(user.protected).to eq(t_user[:protected])
      expect(user.suspended).to eq(t_user[:suspended])
      expect(user.status_created_at).to eq(t_user[:status][:created_at])
      expect(user.account_created_at).to eq(t_user[:created_at])
      expect(user.statuses_count).to eq(t_user[:statuses_count])
      expect(user.favourites_count).to eq(t_user[:favourites_count])
      expect(user.listed_count).to eq(t_user[:listed_count])
      expect(user.name).to eq(t_user[:name])
      expect(user.location).to eq(t_user[:location])
      expect(user.description).to eq(t_user[:description])
      expect(user.geo_enabled).to eq(t_user[:geo_enabled])
      expect(user.verified).to eq(t_user[:verified])
      expect(user.lang).to eq(t_user[:lang])
      expect(user.profile_image_url_https).to eq(t_user[:profile_image_url_https])
      expect(user.profile_banner_url).to eq(t_user[:profile_banner_url])
      expect(user.profile_link_color).to eq(t_user[:profile_link_color])

      expect(user.valid?).to be_truthy
    end

    context 'With suspended user' do
      let(:t_user) { build(:t_user, id: 123, screen_name: 'screen_name') }
      let(:user) { TwitterDB::User.build_by(user: t_user) }

      it do
        expect(user.uid).to eq(t_user[:id])
        expect(user.screen_name).to eq(t_user[:screen_name])
      end
    end
  end

  describe '.import_by!' do
    let(:t_users) { 3.times.map { build(:t_user) } }

    it do
      expect { TwitterDB::User.import_by!(users: t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size)
    end
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
      let(:time) { (TwitterDB::User::Batch::UPDATE_INTERVAL - 1.second).ago.round }
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
