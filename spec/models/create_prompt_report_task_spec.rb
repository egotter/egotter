require 'rails_helper'

RSpec.describe CreatePromptReportTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create!(user_id: user.id) }
  let(:task) { CreatePromptReportTask.new(request) }

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
        expect(task).not_to receive(:update_unfriendships)
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
end
