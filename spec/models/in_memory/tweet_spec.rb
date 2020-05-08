require 'rails_helper'

RSpec.describe InMemory::Tweet do
  let(:client) { spy('client') }
  let(:tweets) do
    [
        {'raw_attrs_text' => {'id' => 1, 'text' => 'text1'}.to_json},
        {'raw_attrs_text' => {'id' => 2, 'text' => 'text2'}.to_json}
    ]
  end

  before do
    allow(described_class).to receive(:client).and_return(client)
  end

  describe '.find_by' do
    let(:uid) { 1 }
    let(:read_result) { ::S3::Util.pack(tweets) }
    subject { described_class.find_by(uid) }
    it do
      expect(client).to receive(:read).with(uid).and_return(read_result)
      expect(described_class).to receive(:decompress).with(read_result).and_call_original

      is_expected.to satisfy do |result|
        result[0].raw_attrs_text == tweets[0]['raw_attrs_text'] &&
            result[1].raw_attrs_text == tweets[1]['raw_attrs_text']
      end
    end
  end

  describe '.delete_by' do
    subject { described_class.delete_by(1) }
    it do
      expect(client).to receive(:delete).with(1)
      subject
    end
  end

  describe '.import_from' do
    subject { described_class.import_from(1, tweets) }
    it do
      expect(described_class).to receive(:compress).with(tweets.to_json).and_return('compress_result')
      expect(client).to receive(:write).with(1, 'compress_result')
      subject
    end
  end

  describe '.compress' do
    subject { described_class.compress(tweets.to_json) }
    it { is_expected.to eq(::S3::Util.pack(tweets)) }
  end

  describe '.decompress' do
    subject { described_class.decompress(::S3::Util.pack(tweets)) }
    it { is_expected.to eq(tweets.to_json) }
  end
end
