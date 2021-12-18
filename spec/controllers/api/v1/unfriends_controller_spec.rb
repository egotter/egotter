require 'rails_helper'

RSpec.describe Api::V1::UnfriendsController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    controller.instance_variable_set(:@twitter_user, twitter_user)
  end

  describe '#summary_uids' do
    let(:resources) { double('resources') }
    subject { controller.send(:summary_uids, limit: described_class::SUMMARY_LIMIT) }

    before do
      allow(resources).to receive_message_chain(:limit, :pluck).with(described_class::SUMMARY_LIMIT).with(:friend_uid).and_return('result1')
      allow(resources).to receive(:size).and_return('result2')
    end

    it do
      expect(twitter_user).to receive(:unfriendships).and_return(resources)
      is_expected.to eq(['result1', 'result2'])
    end
  end

  describe '#list_users' do
    let(:uids) { [1, 2, 2] }
    subject { controller.send(:list_users) }
    before do
      create(:twitter_db_user, uid: uids[0])
      create(:twitter_db_user, uid: uids[1])
    end
    it do
      expect(twitter_user).to receive(:unfriend_uids).and_return(uids)
      result = subject
      expect(result.map(&:uid)).to eq(uids)
    end
  end
end
