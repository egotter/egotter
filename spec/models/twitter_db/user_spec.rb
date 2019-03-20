require 'rails_helper'

RSpec.describe TwitterDB::User, type: :model do
  context 'association' do
    let(:users) { 3.times.map { create(:twitter_db_user) } }
    let(:rest_users) { users - [users[0]] }

  end

  describe '#statuses' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index {|i| create(:twitter_db_status, uid: user.uid, screen_name: user.screen_name, sequence: i)} }
    it 'has many statuses' do
      expect(user.statuses.size).to eq(3)
    end
  end

  describe '#favorites' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index {|i| create(:twitter_db_favorite, uid: user.uid, screen_name: user.screen_name, sequence: i)} }
    it 'has many favorites' do
      expect(user.favorites.size).to eq(3)
    end
  end

  describe '#mentions' do
    let(:user) { create(:twitter_db_user) }
    before { 3.times.each.with_index {|i| create(:twitter_db_mention, uid: user.uid, screen_name: user.screen_name, sequence: i)} }
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
    let(:t_user) do
      {
          id:                      123,
          screen_name:             'screen_name',
          friends_count:           10,
          followers_count:         20,
          protected:               true,
          suspended:               true,
          status:                  {created_at: '2019-01-01 10:00:00'},
          created_at:              '2010-01-01 10:00:00',
          statuses_count:          30,
          favourites_count:        40,
          listed_count:            50,
          name:                    'name',
          location:                'Japan',
          description:             'Hi.',
          url:                     'https://example.com',
          geo_enabled:             true,
          verified:                true,
          lang:                    'ja',
          profile_image_url_https: 'https://profile.image',
          profile_banner_url:      'https://profile.banner',
          profile_link_color:      '123456',
      }
    end

    it do
      user = TwitterDB::User.build_by(user: t_user)

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
      let(:t_user) do
        {id: 123, screen_name: 'screen_name'}
      end

      it do
        user = TwitterDB::User.build_by(user: t_user)
        expect(user.uid).to eq(t_user[:id])
        expect(user.screen_name).to eq(t_user[:screen_name])
      end
    end
  end

  describe '.import' do
    let(:t_users) do
      3.times.map do
        Hashie::Mash.new(
            id: rand(1000_000_000),
            screen_name: 'screen_name',
            name: 'name',
            friends_count: 100,
            followers_count: 200,
            statuses_count: 300,
            favourites_count: 400,
            listed_count: 500,
        )
      end
    end

    let(:import_users) { t_users.map { |t_user| [t_user[:id], t_user[:screen_name], -1, -1] } }

    context 'with new records' do
      it 'creates all records' do
        expect { TwitterDB::User::Batch.import(t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size)
      end
    end

    context 'with new records and recently persisted records' do
      before do
        t_users[0].tap do |t_user|
          TwitterDB::User.create!(uid: t_user[:id], screen_name: t_user[:screen_name])
        end
      end
      it 'updates only new records' do
        expect { TwitterDB::User::Batch.import(t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size - 1)
      end
    end
  end
end
