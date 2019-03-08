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

  describe '.import' do
    let(:t_users) { 3.times.map { Hashie::Mash.new(id: rand(1000_000_000), screen_name: 'sn') } }
    let(:import_users) { t_users.map { |t_user| [t_user[:id], t_user[:screen_name], TwitterUser.collect_user_info(t_user), -1, -1] } }

    context 'with new records' do
      it 'creates all records' do
        expect { TwitterDB::User::Batch.import(t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size)
      end
    end

    context 'with new records and recently persisted records' do
      before do
        t_users[0].tap do |t_user|
          TwitterDB::User.create!(uid: t_user[:id], screen_name: t_user[:screen_name], user_info: TwitterUser.collect_user_info(t_user), friends_size: -1, followers_size: -1)
        end
      end
      it 'updates only new records' do
        expect { TwitterDB::User::Batch.import(t_users) }.to change { TwitterDB::User.all.size }.by(t_users.size - 1)
      end
    end
  end
end
