require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  let(:tu) { build(:twitter_user) }

  let(:client) {
    client = Object.new
    def client.user?(*args)
      true
    end
    def client.user(*args)
      Hashie::Mash.new({id: 1, screen_name: 'sn'})
    end
    client
  }

  describe '#invalid_screen_name?' do
    context 'screen_name has special chars' do
      it 'returns true' do
        (%w(! " # $ % & ' - = ^ ~ ¥ \\ | @ ; + : * [ ] { } < > / ?) + %w[( )]).each do |c|
          tu.screen_name = c * 10
          expect(tu.invalid_screen_name?).to be_truthy
        end
      end
    end

    context 'screen_name has normal chars' do
      it 'returns false' do
        tu.screen_name = 'ego_tter'
        expect(tu.invalid_screen_name?).to be_falsy
      end
    end
  end

  describe '#same_record_exists?' do
    before do
      raise 'save_with_bulk_insert failed' unless tu.save_with_bulk_insert
      @same_tu = build(:twitter_user, uid: tu.uid, screen_name: tu.screen_name)
      @same_tu.friends = tu.friends.map { |f| build(:friend, uid: f.uid, screen_name: f.screen_name) }
      @same_tu.followers = tu.followers.map { |f| build(:follower, uid: f.uid, screen_name: f.screen_name) }
      ajust_friends_and_followers_count(@same_tu)
    end

    context 'same record is persisted' do
      it 'returns true' do
        expect(@same_tu.same_record_exists?).to be_truthy
      end
    end

    context 'no records are persisted' do
      before do
        tu.destroy
      end

      it 'returns true' do
        expect(@same_tu.same_record_exists?).to be_falsey
      end
    end

    context 'friends_count is different' do
      before do
        @same_tu.friends = @same_tu.friends.to_a.slice(0, 1)
        ajust_friends_and_followers_count(@same_tu)
      end

      it 'returns false' do
        expect(@same_tu.same_record_exists?).to be_falsey
      end
    end

    context 'followers_count is different' do
      before do
        @same_tu.followers = @same_tu.followers.to_a.slice(0, 1)
        ajust_friends_and_followers_count(@same_tu)
      end

      it 'returns false' do
        expect(@same_tu.same_record_exists?).to be_falsey
      end
    end
  end
end

def ajust_friends_and_followers_count(tu)
  json = Hashie::Mash.new(JSON.parse(tu.user_info))
  json.friends_count = tu.friends.size
  json.followers_count = tu.followers.size
  tu.user_info = json.to_json
end