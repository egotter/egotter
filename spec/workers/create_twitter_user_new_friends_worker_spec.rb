require 'rails_helper'

RSpec.describe CreateTwitterUserNewFriendsWorker do
  let(:twitter_user) { create(:twitter_user) }
  let(:worker) { described_class.new }

  before do
    allow(twitter_user).to receive(:calc_new_friend_uids).and_return([1, 2, 3])
    allow(TwitterUser).to receive(:find).with(twitter_user.id).and_return(twitter_user)
  end

  describe '#perform' do
    subject { worker.perform(twitter_user.id) }
    it do
      expect(CreateNewFriendsCountPointWorker).to receive(:perform_async).with(twitter_user.id)
      subject
    end
  end
end
