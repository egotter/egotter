require 'rails_helper'

RSpec.describe S3::Tweet do
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

  describe '.where' do
    let(:uid) { 1 }
    let(:obj) { {uid: uid, screen_name: 'sn', tweets: ::S3::Util.pack(tweets), time: Time.zone.now.to_s}.to_json }
    subject { described_class.where(uid: uid) }
    it do
      expect(client).to receive(:read).with(uid).and_return(obj)
      expect(described_class).to receive(:decode).with(obj).and_call_original

      is_expected.to satisfy do |result|
        result[0].raw_attrs_text == tweets[0]['raw_attrs_text'] &&
            result[1].raw_attrs_text == tweets[1]['raw_attrs_text']
      end
    end
  end

  describe '.import_from!' do
    subject { described_class.import_from!(1, 'sn', tweets) }
    it do
      expect(described_class).to receive(:encode).with(1, 'sn', tweets).and_return('body')
      expect(client).to receive(:write).with(1, 'body')
      subject
    end
  end

  describe '.delete' do
    subject { described_class.delete(uid: 1) }
    it do
      expect(client).to receive(:delete).with(1)
      subject
    end
  end

  describe '.encode' do
    subject { described_class.encode(1, 'sn', tweets) }
    it do
      is_expected.to eq({uid: 1, screen_name: 'sn', tweets: ::S3::Util.pack(tweets), time: Time.zone.now.to_s}.to_json)
    end
  end

  describe '.decode' do
    let(:obj) { {uid: 1, screen_name: 'sn', tweets: ::S3::Util.pack(tweets), time: Time.zone.now.to_s}.to_json }
    subject { described_class.decode(obj) }
    it do
      is_expected.to eq({'uid' => 1, 'screen_name' => 'sn', 'tweets' => tweets, 'time' => Time.zone.now.to_s})
    end
  end
end
