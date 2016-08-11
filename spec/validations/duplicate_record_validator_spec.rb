require 'rails_helper'

RSpec.describe Validations::DuplicateRecordValidator do
  subject(:tu) { build(:twitter_user) }

  describe '#same_record_exists?' do
    before { allow_any_instance_of(Validations::DuplicateRecordValidator).to receive(:recently_created_record_exists?).and_return(false) }

    context 'with a same record' do
      before { create_same_record!(tu) }
      it { is_expected.to be_invalid }
    end

    context 'without same records' do
      before { create_same_record!(build(:twitter_user)) }
      it { is_expected.to be_valid }
    end

    context 'friends_count is different' do
      before do
        record = create_same_record!(tu)
        record.friends.first.destroy
        ajust_user_info(record)
      end
      it { is_expected.to be_valid }
    end

    context 'followers_count is different' do
      before do
        record = create_same_record!(tu)
        record.followers.first.destroy
        ajust_user_info(record)
      end
      it { is_expected.to be_valid }
    end
  end

  describe '#recently_created_record_exists?' do
    before { allow_any_instance_of(Validations::DuplicateRecordValidator).to receive(:same_record_exists?).and_return(false) }

    context 'with a recently created record' do
      before { create_same_record!(tu) }
      it { is_expected.to be_invalid }
    end

    context 'without recently created records' do
      before do
        record = create_same_record!(tu)
        record.update!(created_at: 1.days.ago, updated_at: 1.days.ago)
      end
      it { is_expected.to be_valid }
    end
  end
end

def create_same_record!(tu)
  same_tu = build(:twitter_user, uid: tu.uid, screen_name: tu.screen_name)
  same_tu.friends = tu.friends.map { |f| build(:friend, uid: f.uid, screen_name: f.screen_name) }
  same_tu.followers = tu.followers.map { |f| build(:follower, uid: f.uid, screen_name: f.screen_name) }
  ajust_user_info(same_tu)
  same_tu.save!
  same_tu
end

def ajust_user_info(tu)
  json = Hashie::Mash.new(JSON.parse(tu.user_info))
  json.friends_count = tu.friends.size
  json.followers_count = tu.followers.size
  tu.user_info = json.to_json
end