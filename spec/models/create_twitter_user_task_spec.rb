require 'rails_helper'

RSpec.describe CreateTwitterUserTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_twitter_user_request, user_id: user.id, uid: 1) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    let(:context) { 'context' }
    let(:twitter_user) { 'twitter_user' }
    subject { task.start!(context) }

    it do
      expect(request).to receive(:perform!).with(context).and_return(twitter_user)
      expect(request).to receive(:finished!)
      expect(task).to receive(:update_friends_and_followers).with(twitter_user, request)
      subject
    end
  end

  describe '#update_friends_and_followers' do
    let(:twitter_user) { instance_double(TwitterUser, created_at: Time.zone.now) }
    subject { task.send(:update_friends_and_followers, twitter_user, request) }

    before do
      allow(twitter_user).to receive(:uid).and_return(1)
      allow(twitter_user).to receive(:friend_uids).and_return([2, 3, 4])
      allow(twitter_user).to receive(:follower_uids).and_return([3, 4, 5])
    end

    it do
      expect(CreateTwitterDBUserWorker).to receive(:compress).with([1, 2, 3, 4, 5]).and_return('compressed_uids')
      expect(CreateTwitterDBUserWorker).to receive(:perform_async).
          with('compressed_uids', user_id: request.user_id, request_id: request.id, compressed: true, enqueued_by: instance_of(String))
      subject
    end
  end
end
