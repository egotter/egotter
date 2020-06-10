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
      expect(task).to receive(:update_target_user).with(request)
      expect(request).to receive(:perform!).with(context).and_return(twitter_user)
      expect(request).to receive(:finished!)
      expect(task).to receive(:update_friends_and_followers).with(twitter_user)
      subject
    end
  end

  describe '#update_target_user' do
    subject { task.send(:update_target_user, request) }
    it do
      expect(CreateTwitterDBUserWorker).to receive(:perform_async).
          with([request.uid], user_id: request.user_id, force_update: true, enqueued_by: instance_of(String))
      subject
    end
  end

  describe '#update_friends_and_followers' do
    let(:twitter_user) { instance_double(TwitterUser) }
    subject { task.send(:update_friends_and_followers, twitter_user) }

    before do
      allow(twitter_user).to receive(:uid).and_return(1)
      allow(twitter_user).to receive(:friend_uids).and_return([2, 3, 4])
      allow(twitter_user).to receive(:follower_uids).and_return([3, 4, 5])
    end

    it do
      expect(CreateTwitterDBUserWorker).to receive(:compress).with([1, 2, 3, 4, 5]).and_return('compressed')
      expect(CreateTwitterDBUserWorker).to receive(:perform_async).
          with('compressed', user_id: request.user_id, compressed: true, enqueued_by: instance_of(String))
      subject
    end
  end
end
