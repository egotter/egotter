require 'rails_helper'

RSpec.describe UnfriendUser, type: :model do
  describe '#account_suspended?' do
    subject { described_class.new(account_status: 'suspended').account_suspended? }
    it { is_expected.to be_truthy }
  end

  describe '#account_deleted?' do
    subject { described_class.new(account_status: 'deleted').account_deleted? }
    it { is_expected.to be_truthy }
  end

  describe '.twitter_db_user_to_import_data' do
    let(:user) { create(:twitter_db_user) }
    subject { described_class.twitter_db_user_to_import_data(user) }
    it do
      result = subject
      expect(result[0]).to eq(user.uid)
      expect(result[1]).to eq(user.screen_name)
      expect(result[2]).to eq(user.friends_count)
      expect(result[3]).to eq(user.followers_count)
      expect(result[4]).to eq(user.protected)
      expect(result[5]).to eq(user.suspended)
      expect(result[6]).to eq(user.status_created_at)
      expect(result[7]).to eq(user.account_created_at)
      expect(result[8]).to eq(user.statuses_count)
      expect(result[9]).to eq(user.favourites_count)
      expect(result[10]).to eq(user.listed_count)
      expect(result[11]).to eq(user.name)
      expect(result[12]).to eq(user.location)
      expect(result[13]).to eq(user.description)
      expect(result[14]).to eq(user.url)
      expect(result[15]).to eq(user.verified)
      expect(result[16]).to eq(user.profile_image_url_https)
    end
  end

  describe '.raw_user_to_import_data' do
    let(:user) { build(:t_user).to_h.deep_symbolize_keys }
    subject { described_class.raw_user_to_import_data(user) }
    it do
      result = subject
      expect(result[0]).to eq(user[:id])
      expect(result[1]).to eq(user[:screen_name])
      expect(result[2]).to eq(user[:friends_count])
      expect(result[3]).to eq(user[:followers_count])
      expect(result[4]).to eq(user[:protected])
      expect(result[5]).to eq(user[:suspended])
      expect(result[6]).to eq(user[:status][:created_at])
      expect(result[7]).to eq(user[:created_at])
      expect(result[8]).to eq(user[:statuses_count])
      expect(result[9]).to eq(user[:favourites_count])
      expect(result[10]).to eq(user[:listed_count])
      expect(result[11]).to eq(user[:name])
      expect(result[12]).to eq(user[:location])
      expect(result[13]).to eq(user[:description])
      expect(result[14]).to eq(user[:url])
      expect(result[15]).to eq(user[:verified])
      expect(result[16]).to eq(user[:profile_image_url_https])
    end
  end

  describe '.import_data' do
    let(:from_uid) { 100 }
    let(:raw_data) do
      [
          {id: 1, screen_name: 'sn1', created_at: 1.day.ago},
          {id: 2, screen_name: 'sn2', created_at: 1.day.ago},
      ]
    end
    subject { described_class.import_data(from_uid, raw_data) }

    context 'Records do not exist' do
      it do
        expect { subject }.to change { described_class.all.size }.by(2)
        expect(described_class.pluck(:uid)).to eq([1, 2])
      end
    end

    context 'Records already exist' do
      before do
        raw_data.each.with_index do |d, i|
          create(:unfriend_user, from_uid: from_uid, uid: d[:id], screen_name: d[:screen_name], sort_order: i)
        end
      end
      it do
        expect { subject }.not_to change { described_class.all.size }
        expect(described_class.pluck(:uid)).to eq([1, 2])
      end
    end
  end
end
