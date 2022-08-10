require 'rails_helper'

RSpec.describe WriteS3ProfileWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:data) { 'data' }
    let(:hash) { {'twitter_user_id' => 1, 'uid' => 2, 'screen_name' => 'sn', 'profile' => 'p'} }
    subject { worker.perform(data) }
    it do
      expect(worker).to receive(:decompress).with(data).and_return(hash)
      expect(S3::Profile).to receive(:import_from!).with(1, 2, 'sn', 'p', async: false)
      subject
    end
  end
end
