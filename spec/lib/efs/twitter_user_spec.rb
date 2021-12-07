require 'rails_helper'

RSpec.describe Efs::TwitterUser do
  describe '.find_by' do
    let(:twitter_user_id) { 123 }
    subject { described_class.find_by(twitter_user_id) }

    it do
      expect(described_class.client).to receive(:read).with(twitter_user_id).and_return('raw_data')
      expect(described_class).to receive(:unpack).with('raw_data').and_return('data')
      expect(described_class).to receive(:new).with('data')
      subject
    end
  end

  describe '.delete_by' do
    let(:twitter_user_id) { 123 }
    subject { described_class.delete_by(twitter_user_id) }
    it do
      expect(described_class.client).to receive(:delete).with(twitter_user_id)
      subject
    end
  end

  describe '.exists?' do
    let(:twitter_user_id) { 123 }
    subject { described_class.exists?(twitter_user_id) }
    it do
      expect(described_class.client).to receive(:exist?).with(twitter_user_id)
      subject
    end
  end

  describe '.import_from!' do
    let(:twitter_user_id) { 123 }
    let(:data) do
      {
          twitter_user_id: twitter_user_id,
          uid: 456,
          screen_name: 'name',
          profile: {dummy: true},
          friend_uids: [1, 2, 3],
          follower_uids: [4, 5, 6],
      }
    end
    subject { described_class.import_from!(*data.values) }

    it do
      expect(described_class).to receive(:pack).with(data).and_return('payload')
      expect(described_class.client).to receive(:write).with(twitter_user_id, 'payload')
      subject
    end
  end

  describe '.pack' do
    let(:data) { {a: 1, b: 2} }
    subject { described_class.pack(data) }
    it { is_expected.to eq(Zlib::Deflate.deflate(data.to_json)) }
  end

  describe '.unpack' do
    let(:raw_data) { Zlib::Deflate.deflate({a: 1, b: 2}.to_json) }
    subject { described_class.unpack(raw_data) }
    it do
      data = subject
      expect(data[:a]).to eq(1)
      expect(data[:b]).to eq(2)
    end
  end
end
