require 'rails_helper'

RSpec.describe CreateFollowTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:follow_request, user_id: user.id) }
  let(:task) { CreateFollowTask.new(request) }

  describe '#start!' do
    context 'The request.perform! raises FollowRequest::AlreadyFollowing' do
      let!(:records) do
        [
            create(:follow_request, user_id: user.id, uid: request.uid),
            create(:follow_request, user_id: user.id, uid: request.uid + 1),
            create(:follow_request, user_id: user.id, uid: request.uid, finished_at: Time.zone.now),
            create(:follow_request, user_id: user.id, uid: request.uid, error_class: 'Error'),
        ]
      end
      subject { task.start! }

      before do
        allow(request).to receive(:perform!).with(no_args).and_raise(FollowRequest::AlreadyFollowing)
      end

      it 'updates records with the same user_id and uid' do
        expect { subject }.to raise_error(FollowRequest::AlreadyFollowing)

        records.each(&:reload)

        expect(records[0]).to satisfy { |r| r.error_class == 'FollowRequest::AlreadyFollowing' }.
            and satisfy { |r| r.error_message == 'Bulk update' }

        records.reject.with_index { |_, i| i == 0 }.each do |record|
          expect(record).not_to satisfy { |r| r.error_class == 'FollowRequest::AlreadyFollowing' }
          expect(record).not_to satisfy { |r| r.error_message == 'Bulk update' }
        end
      end
    end
  end
end
