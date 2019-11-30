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
    let(:t_users) { 3.times.map { build(:t_user) } }
    let(:import_users) { t_users.map { |t_user| [t_user[:id], t_user[:screen_name], -1, -1] } }

    context 'with new records' do
      it 'creates all records' do
        expect { TwitterDB::User::Batch.import(t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size)
      end
    end

    context 'with new records and recently persisted records' do
      before do
        TwitterDB::User.create!(uid: t_users[0][:id], screen_name: t_users[0][:screen_name])
      end
      it 'updates only new records' do
        expect { TwitterDB::User::Batch.import(t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size - 1)
      end
    end
  end
end
