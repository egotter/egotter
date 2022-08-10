require 'rails_helper'

RSpec.describe WriteEfsTwitterUserWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:data) { 'data' }
    let(:hash) { {'twitter_user_id' => 1, 'uid' => 2, 'screen_name' => 'sn', 'profile' => 'p', 'friend_uids' => [1, 2], 'follower_uids' => [3, 4]} }
    subject { worker.perform(data) }
    it do
      expect(worker).to receive(:decompress).with(data).and_return(hash)
      expect(Efs::TwitterUser).to receive(:import_from!).with(1, 2, 'sn', 'p', [1, 2], [3, 4])
      subject
    end
  end
end
