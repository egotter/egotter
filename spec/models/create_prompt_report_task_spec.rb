require 'rails_helper'

RSpec.describe CreatePromptReportTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create!(user_id: user.id) }
  let(:task) { CreatePromptReportTask.new(request) }

  describe '#start!' do
    let(:twitter_user) { create(:twitter_user, uid: user.uid) }
    it do
      expect(request).to receive(:error_check!).with(no_args)
      expect(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)
      expect(request).to receive(:perform!).with(twitter_user)
      expect(request).to receive(:finished!).with(no_args)
      task.start!
    end

    context 'request.kind == :you_are_removed' do
      before do
        request.kind = :you_are_removed
        allow(request).to receive(:error_check!).with(no_args)
        allow(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)
        allow(request).to receive(:perform!).with(twitter_user)
      end
      it do
        expect(task).to receive(:update_api_caches).with(twitter_user)
        task.start!
      end
    end

    context 'request.kind == :not_changed' do
      before do
        request.kind = :not_changed
        allow(request).to receive(:error_check!).with(no_args)
        allow(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)
        allow(request).to receive(:perform!).with(twitter_user)
      end
      it do
        expect(task).to receive(:update_api_caches).with(twitter_user)
        task.start!
      end
    end
  end

  describe '#create_twitter_user!' do
    subject { task.create_twitter_user!(user) }

    before do
      allow(CreateTwitterUserTask).to receive(:new).with(anything).and_raise(RuntimeError, 'Hello')
    end

    context 'There is one record' do
      let(:record) { build(:twitter_user, uid: user.uid) }
      before { record.save!(validate: false) }

      it do
        expect(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(record)
        expect(task).to receive(:update_unfriendships).with(record)
        expect { subject }.to raise_error(RuntimeError, 'Hello')
      end
    end

    context 'There is no records' do
      it do
        expect(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(nil)
        expect(task).to receive(:update_unfriendships).with(nil)
        expect { subject }.to raise_error(RuntimeError, 'Hello')
      end
    end
  end

  describe '#update_unfriendships' do
    let(:record) { build(:twitter_user, uid: user.uid) }
    before { record.save!(validate: false) }
    subject { task.update_unfriendships(record) }

    it do
      expect(Unfriendship).to receive(:import_by!).with(twitter_user: record).and_call_original
      expect(Unfollowership).to receive(:import_by!).with(twitter_user: record).and_call_original
      subject
    end
  end

  describe '#update_api_caches' do
    let(:twitter_user) { create(:twitter_user, uid: user.uid) }
    let(:unfollowers) { 3.times.map { |i| double('Unfollower', uid: i, screen_name: "sn#{i}") } }
    before do
      allow(twitter_user).to receive(:unfollowers).with(no_args).and_return(unfollowers)
    end
    it do
      unfollowers.each do |unfollower|
        expect(FetchUserForCachingWorker).to receive(:perform_async).with(unfollower.uid, hash_including(user_id: request.user.id))
        expect(FetchUserForCachingWorker).to receive(:perform_async).with(unfollower.screen_name, hash_including(user_id: request.user.id))
      end
      task.update_api_caches(twitter_user)
    end
  end
end
