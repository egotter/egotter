require 'rails_helper'

RSpec.describe CacheDirectory, type: :model do
  describe '#rotate!' do
    let(:directory) { CacheDirectory.create(name: 'twitter', dir: 'tmp/twitter_test_20190311') }
    it do
      directory.rotate!
      expect(directory.dir).to eq('tmp/twitter_test_' + Time.zone.now.strftime('%Y%m%d'))
    end
  end
end
