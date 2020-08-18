require 'rails_helper'

RSpec.describe Efs::TwitterUser do
  let(:client) { spy('client') }

  before do
    allow(described_class).to receive(:cache_client).and_return(client)
  end

  describe '.find_by' do
    let(:twitter_user_id) { 123 }
    let(:cache_key) { "efs_twitter_user_cache:#{twitter_user_id}" }
    let(:twitter_user) { attributes_for(:twitter_user, with_relations: false) }
    let(:read_result) { Zlib::Deflate.deflate(twitter_user.to_json) }
    subject { described_class.find_by(twitter_user_id) }

    before { allow(client).to receive(:read).with(cache_key).and_return(read_result) }

    it do
      is_expected.to satisfy do |result|
        result.uid == twitter_user[:uid] &&
            result.screen_name == twitter_user[:screen_name] &&
            result.profile == twitter_user[:profile] &&
            result.friend_uids == twitter_user[:friend_uids] &&
            result.follower_uids == twitter_user[:follower_uids]
      end
    end
  end

  describe '.delete_by' do
    let(:twitter_user_id) { 123 }
    let(:cache_key) { "efs_twitter_user_cache:#{twitter_user_id}" }
    subject { described_class.delete_by(twitter_user_id) }
    it do
      expect(client).to receive(:delete).with(cache_key)
      subject
    end
  end

  describe '.import_from!' do
    let(:twitter_user) { create(:twitter_user) }
    let(:cache_key) { "efs_twitter_user_cache:#{twitter_user.id}" }
    let(:payload) do
      {
          twitter_user_id: twitter_user.id,
          uid: twitter_user.uid,
          screen_name: twitter_user.screen_name,
          profile: {dummy: true},
          friend_uids: 'friend_uids',
          follower_uids: 'follower_uids',
      }.to_json
    end
    subject { described_class.import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, '{"dummy": true}', 'friend_uids', 'follower_uids') }

    before do
      allow(described_class).to receive(:compress).with(payload).and_return('compressed')
      allow(client).to receive(:write).with(cache_key, 'compressed').and_return('result')
    end

    it { is_expected.to eq('result') }
  end
end
