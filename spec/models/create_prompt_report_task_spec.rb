require 'rails_helper'

RSpec.describe CreatePromptReportTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create!(user_id: user.id) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    let(:twitter_user) { build(:twitter_user, uid: user.uid) }
    let(:persisted_record) { build(:twitter_user, uid: user.uid) }
    subject { task.start! }

    before do
      twitter_user.save!(validate: false)
      allow(TwitterUser).to receive(:latest_by).with(uid: request.user.uid).and_return(persisted_record)
    end

    it do
      expect(request).to receive(:error_check!).with(no_args)
      expect(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)

      expect(persisted_record).to receive(:calc_unfriend_uids).and_return([1])
      expect(task).to receive(:update_unfriendships).with(persisted_record.uid, [1])

      expect(persisted_record).to receive(:calc_unfollower_uids).and_return([2])
      expect(task).to receive(:update_unfollowerships).with(persisted_record.uid, [2])

      expect(request).to receive(:perform!).with(twitter_user)
      expect(request).to receive(:finished!).with(no_args)
      subject
    end

    context 'create_twitter_user! raises an exception' do
      before do
        allow(request).to receive(:error_check!).with(no_args)
        allow(task).to receive(:create_twitter_user!).with(anything).and_raise('Anything')
      end
      it do
        expect(task).to receive(:update_unfriendships).with(twitter_user.uid, anything)
        expect(task).to receive(:update_unfollowerships).with(twitter_user.uid, anything)
        expect { subject }.to raise_error('Anything')
      end
    end

    context 'request.kind == :you_are_removed' do
      before do
        request.kind = :you_are_removed
        allow(request).to receive(:error_check!).with(no_args)
        allow(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)
        allow(request).to receive(:perform!).with(twitter_user)
        allow(TwitterUser).to receive(:latest_by).with(uid: request.user.uid).and_return(twitter_user)
      end
      it do
        expect(task).to receive(:update_api_caches).with(twitter_user)
        subject
      end
    end

    context 'request.kind == :not_changed' do
      before do
        request.kind = :not_changed
        allow(request).to receive(:error_check!).with(no_args)
        allow(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)
        allow(request).to receive(:perform!).with(twitter_user)
        allow(TwitterUser).to receive(:latest_by).with(uid: request.user.uid).and_return(twitter_user)
      end
      it do
        expect(task).to receive(:update_api_caches).with(twitter_user)
        subject
      end
    end

    context 'The value of request.kind is neither :you_are_removed nor :no_changed' do
      before do
        request.kind = :something_invalid
        allow(request).to receive(:error_check!).with(no_args)
        allow(task).to receive(:create_twitter_user!).with(request.user).and_return(twitter_user)
        allow(request).to receive(:perform!).with(twitter_user)
      end
      it do
        expect(task).not_to receive(:update_api_caches)
        subject
      end
    end
  end

  describe '#create_twitter_user!' do
    subject { task.create_twitter_user!(user) }

    context 'CreateTwitterUserTask raises CreateTwitterUserRequest::NotChanged' do
      before { allow(CreateTwitterUserTask).to receive(:new).with(anything).and_raise(CreateTwitterUserRequest::NotChanged) }
      it { is_expected.to be_nil }
    end

    context 'CreateTwitterUserTask raises CreateTwitterUserRequest::TooShortCreateInterval' do
      before { allow(CreateTwitterUserTask).to receive(:new).with(anything).and_raise(CreateTwitterUserRequest::TooShortCreateInterval) }
      it { is_expected.to be_nil }
    end

    context 'CreateTwitterUserTask raises CreateTwitterUserRequest::TooManyFriends' do
      before { allow(CreateTwitterUserTask).to receive(:new).with(anything).and_raise(CreateTwitterUserRequest::TooManyFriends) }
      it { is_expected.to be_nil }
    end
  end

  describe '#update_unfriendships' do
    let(:record) { build(:twitter_user, uid: user.uid) }
    let(:uids) { [1, 2, 3] }
    before { record.save!(validate: false) }
    subject { task.update_unfriendships(record.uid, uids) }

    it do
      expect(Unfriendship).to receive(:import_from!).with(record.uid, uids).and_call_original
      subject
    end
  end

  describe '#update_unfollowerships' do
    let(:record) { build(:twitter_user, uid: user.uid) }
    let(:uids) { [1, 2, 3] }
    before { record.save!(validate: false) }
    subject { task.update_unfollowerships(record.uid, uids) }

    it do
      expect(Unfollowership).to receive(:import_from!).with(record.uid, uids).and_call_original
      subject
    end
  end

  # describe '#update_api_caches' do
  #   let(:twitter_user) { create(:twitter_user, uid: user.uid) }
  #   let(:unfollowers) { 3.times.map { |i| double('Unfollower', uid: i, screen_name: "sn#{i}") } }
  #   before do
  #     allow(twitter_user).to receive(:unfollowers).with(no_args).and_return(unfollowers)
  #   end
  #   it do
  #     unfollowers.each do |unfollower|
  #       expect(FetchUserForCachingWorker).to receive(:perform_async).with(unfollower.uid, hash_including(user_id: request.user.id))
  #       expect(FetchUserForCachingWorker).to receive(:perform_async).with(unfollower.screen_name, hash_including(user_id: request.user.id))
  #     end
  #     task.update_api_caches(twitter_user)
  #   end
  # end
end
