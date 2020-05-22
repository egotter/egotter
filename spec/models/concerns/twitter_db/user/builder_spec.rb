require 'rails_helper'

RSpec.describe Concerns::TwitterDB::User::Builder do
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
end
