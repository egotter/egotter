require 'rails_helper'

RSpec.describe CreateTwitterDBSortCacheWorker do
  let(:worker) { described_class.new }
  let(:redis) { TwitterDB::SortCache.instance.instance_variable_get(:@redis) }

  before { redis.flushall }

  describe '#perform' do
    subject { worker.perform('friends_desc', 'data') }
    it do
      expect(worker).to receive(:decompress).with('data').and_return('decompressed')
      expect(worker).to receive(:do_perform).with('friends_desc', 'decompressed')
      subject
    end
  end

  describe '#do_perform' do
    let(:uids) { [1, 2, 3] }
    subject { worker.send(:do_perform, 'friends_desc', uids) }
    before do
      create(:twitter_db_user, uid: 1, friends_count: 20)
      create(:twitter_db_user, uid: 2, friends_count: 10)
      create(:twitter_db_user, uid: 3, friends_count: 30)
    end
    it do
      expect(TwitterDB::SortCache.instance).to receive(:write).
          with('friends_desc', [1, 2, 3], [3, 1, 2])
      subject
    end
  end
end
