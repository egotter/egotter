require 'rails_helper'

RSpec.describe Efs::Tweet do
  let(:cache) { spy('cache', ttl: 'ttl') }
  let(:tweets) { [{'id' => 1, 'text' => 'text'}] }

  before do
    described_class.instance_variable_set(:@cache, cache)
  end

  describe '.where' do
    let(:uid) { 1 }
    let(:obj) { {uid: uid, screen_name: 'sn', tweets: ::S3::Util.pack(tweets), time: Time.zone.now.to_s}.to_json }
    subject { described_class.where(uid: uid) }
    it do
      expect(cache).to receive(:get_object).with(uid).and_return(obj)
      expect(described_class).to receive(:decode).with(obj).and_call_original
      is_expected.to match(tweets)
    end
  end

  describe '.import_from!' do
    subject { described_class.import_from!(1, 'sn', tweets) }
    it do
      expect(described_class).to receive(:encode).with(1, 'sn', tweets).and_return('body')
      expect(cache).to receive(:put_object).with(1, 'body')
      subject
    end
  end

  describe '.delete' do
    subject { described_class.delete(uid: 1) }
    it do
      expect(cache).to receive(:delete_object).with(1)
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
