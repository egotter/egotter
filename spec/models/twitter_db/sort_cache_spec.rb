require 'rails_helper'

RSpec.describe TwitterDB::SortCache, type: :model do
  let(:instance) { described_class.instance }
  let(:sort_value) { 'friends_desc' }
  let(:uids) { [1, 2, 3] }
  let(:redis) { instance.instance_variable_get(:@redis) }

  before { redis.flushall }

  context 'integration test' do
    let(:ary) { [10, 11, 12] }
    it do
      expect(instance.exists?(sort_value, uids)).to be_falsey
      instance.write(sort_value, uids, ary)
      expect(instance.exists?(sort_value, uids)).to be_truthy
      expect(instance.read(sort_value, uids)).to eq(ary)
    end
  end

  describe '#read' do
    subject { instance.read(sort_value, uids) }
    it do
      expect(instance).to receive(:key).with(sort_value, uids).and_return('key')
      expect(redis).to receive(:get).with('key').and_return('compressed')
      expect(instance).to receive(:decompress).with('compressed').and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#write' do
    let(:ary) { [10, 11, 12] }
    subject { instance.write(sort_value, uids, ary) }
    it do
      expect(instance).to receive(:key).with(sort_value, uids).and_return('key')
      expect(instance).to receive(:compress).with(ary).and_return('compressed')
      expect(redis).to receive(:setex).with('key', 300, 'compressed')
      subject
    end
  end

  describe '#exists?' do
    subject { instance.exists?(sort_value, uids) }
    it do
      expect(instance).to receive(:key).with(sort_value, uids).and_return('key')
      expect(redis).to receive(:exists?).with('key').and_return('result')
      expect(redis).to receive(:ttl).with('key').and_return(10)
      is_expected.to be_truthy
    end
  end

  describe '#key' do
    subject { instance.send(:key, sort_value, uids) }
    before { allow(Digest::MD5).to receive(:hexdigest).with(uids.to_json).and_return('digest') }
    it do
      is_expected.to eq('test:sort_cache:friends_desc:digest')
    end
  end
end
