require 'rails_helper'

RSpec.describe Api::V1::UnfollowersController, type: :controller do
  let(:twitter_user) { create(:twitter_user) }

  before do
    controller.instance_variable_set(:@twitter_user, twitter_user)
  end

  describe '#summary_uids' do
    let(:resources) { double('resources') }
    subject { controller.send(:summary_uids, limit: described_class::SUMMARY_LIMIT) }

    before do
      allow(resources).to receive_message_chain(:limit, :pluck).with(described_class::SUMMARY_LIMIT).with(:follower_uid).and_return('result1')
      allow(resources).to receive(:size).and_return('result2')
    end

    it do
      expect(twitter_user).to receive(:unfollowerships).and_return(resources)
      is_expected.to eq(['result1', 'result2'])
    end
  end

  describe '#list_users' do
    subject { controller.send(:list_users) }
    it do
      expect(twitter_user).to receive(:unfollowers).and_return('result')
      is_expected.to eq('result')
    end
  end
end
