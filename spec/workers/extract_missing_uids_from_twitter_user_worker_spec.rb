require 'rails_helper'

RSpec.describe ExtractMissingUidsFromTwitterUserWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:twitter_user) { double('twitter_user', id: 1, user_id: 2, friend_uids: [1, 2, 3], follower_uids: [2, 3, 4]) }
    let(:uids) { [1, 2, 3] }
    subject { worker.perform(twitter_user.id) }
    before { allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user) }
    it do
      expect(CreateTwitterDBUsersForMissingUidsWorker).to receive(:perform_async).with([1, 2, 3, 4], twitter_user.user_id)
      subject
    end
  end
end
