require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  let(:tu) { FactoryGirl.build(:twitter_user) }
  let(:friend) { FactoryGirl.build(:friend) }
  let(:follower) { FactoryGirl.build(:follower) }

  let(:new_tu) { FactoryGirl.build(:twitter_user) }
  let(:new_friend) { FactoryGirl.build(:friend) }
  let(:new_follower) { FactoryGirl.build(:follower) }

  describe '#invalid_screen_name?' do
    context 'special chars' do
      it 'returns true' do
        (%w(! " # $ % & ' - = ^ ~ ¥ \\ | @ ; + : * [ ] { } < > / ?) + %w[( )]).each do |c|
          tu.screen_name = c
          expect(tu.invalid_screen_name?).to be_truthy
        end
      end
    end

    context 'normal chars' do
      it 'returns false' do
        tu.screen_name = 'ego_tter'
        expect(tu.invalid_screen_name?).to be_falsy
      end
    end
  end

  describe '#same_record_exists?' do
    before do
      tu.save(validate: false)
      friend.from_id = tu.id; friend.save(validate: false)
      follower.from_id = tu.id; follower.save(validate: false)
      tu.friends = [friend]; tu.followers = [follower]; tu.save
      new_tu.friends = [new_friend]; new_tu.followers = [new_follower]
    end

    context 'same record is persisted' do
      it 'returns true' do
        expect(new_tu.same_record_exists?).to be_truthy
      end
    end

    context 'same record is not persisted' do
      before do
        tu.destroy
      end

      it 'returns true' do
        expect(new_tu.same_record_exists?).to be_falsey
      end
    end

    context 'friends_count is different' do
      before do
        json = Hashie::Mash.new(JSON.parse(new_tu.user_info))
        json.friends_count += 1
        new_tu.user_info = json.to_json
      end

      it 'returns false' do
        expect(new_tu.same_record_exists?).to be_falsey
      end
    end

    context 'followers_count is different' do
      before do
        json = Hashie::Mash.new(JSON.parse(new_tu.user_info))
        json.followers_count += 1
        new_tu.user_info = json.to_json
      end

      it 'returns false' do
        expect(new_tu.same_record_exists?).to be_falsey
      end
    end
  end
end
