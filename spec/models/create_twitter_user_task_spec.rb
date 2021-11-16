require 'rails_helper'

RSpec.describe CreateTwitterUserTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_twitter_user_request, user_id: user.id, uid: 1) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    let(:context) { 'context' }
    let(:twitter_user) { 'twitter_user' }
    subject { task.start!(context) }

    before do
      allow(task).to receive(:idle_time?).and_return(true)
    end

    it do
      expect(request).to receive(:perform!).with(context).and_return(twitter_user)
      expect(request).to receive(:finished!)
      expect(task).to receive(:update_new_friends_and_new_followers).with(twitter_user, user.id).and_return([1])
      expect(task).to receive(:update_friends_and_followers).with(twitter_user, user.id, [1])
      subject
    end
  end

  describe '#update_new_friends_and_new_followers' do
    let(:twitter_user) { instance_double(TwitterUser, uid: 1, calc_new_friend_uids: [2, 3, 4], calc_new_follower_uids: [3, 4, 5], created_at: Time.zone.now) }
    subject { task.send(:update_new_friends_and_new_followers, twitter_user, user.id) }

    it do
      expect(CreateHighPriorityTwitterDBUserWorker).to receive(:compress_and_perform_async).
          with([1, 2, 3, 4, 5], user_id: user.id, enqueued_by: instance_of(String))
      subject
    end
  end

  describe '#update_friends_and_followers' do
    let(:twitter_user) { instance_double(TwitterUser, uid: 1, friend_uids: [2, 3, 4], follower_uids: [3, 4, 5]) }
    let(:reject_uids) { [3, 4] }
    subject { task.send(:update_friends_and_followers, twitter_user, user.id, reject_uids) }

    it do
      expect(CreateTwitterDBUserWorker).to receive(:compress_and_perform_async).
          with([2, 5], user_id: user.id, enqueued_by: instance_of(String))
      subject
    end
  end
end
