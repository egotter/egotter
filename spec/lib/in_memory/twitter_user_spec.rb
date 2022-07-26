require 'rails_helper'

RSpec.describe InMemory::TwitterUser do
  let(:client) { spy('client') }
  let(:twitter_user_id) { 123 }

  before do
    allow(described_class).to receive(:client).and_return(client)
  end

  describe '.find_by' do
    let(:twitter_user) { attributes_for(:twitter_user, with_relations: false) }
    let(:read_result) { Base64.encode64(Zlib::Deflate.deflate(twitter_user.to_json)) }
    subject { described_class.find_by(twitter_user_id) }

    before { allow(client).to receive(:read).with(twitter_user_id).and_return(read_result) }

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
    subject { described_class.delete_by(twitter_user_id) }
    it do
      expect(client).to receive(:delete).with(twitter_user_id)
      subject
    end
  end

  describe '.import_from' do
    let(:payload) { {uid: 222, screen_name: 'sn', profile: {}, friend_uids: [1], follower_uids: [2]}.to_json }
    subject { described_class.import_from(111, 222, 'sn', {}, [1], [2]) }
    before do
      expect(described_class).to receive(:compress).with(payload).and_return('compressed')
      expect(client).to receive(:write).with(111, 'compressed').and_return('result')
    end
    it { is_expected.to eq('result') }
  end
end
