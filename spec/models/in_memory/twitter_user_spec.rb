require 'rails_helper'

RSpec.describe InMemory::TwitterUser do
  let(:client) { spy('client') }
  let(:twitter_user_id) { 2 }

  before do
    allow(described_class).to receive(:client).and_return(client)
  end

  describe '.find_by' do
    let(:twitter_user) do
      attributes_for(:twitter_user, with_relations: false)
    end
    let(:read_result) { Base64.encode64(Zlib::Deflate.deflate(twitter_user.to_json)) }
    subject { described_class.find_by(twitter_user_id) }

    it do
      expect(client).to receive(:read).with(twitter_user_id).and_return(read_result)
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
    subject { described_class.delete_by(twitter_user_id) }
    it do
      expect(client).to receive(:delete).with(twitter_user_id)
      subject
    end
  end

  describe '.import_from' do
    let(:payload) { {uid: 222, screen_name: 'sn', profile: {}, friend_uids: [1], follower_uids: [2]} }
    subject { described_class.import_from(111, 222, 'sn', {}, [1], [2]) }
    it do
      expect(described_class).to receive(:compress).with(payload.to_json).and_return('compress_result')
      expect(client).to receive(:write).with(111, 'compress_result')
      subject
    end
  end

  describe '.import_from_twitter_user' do
    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    subject { described_class.import_from_twitter_user(twitter_user) }
    it do
      expect(described_class).to receive(:import_from).
          with(twitter_user.id, twitter_user.uid, twitter_user.screen_name, any_args)
      subject
    end
  end
end
