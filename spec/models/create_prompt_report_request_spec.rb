require 'rails_helper'

RSpec.describe CreatePromptReportRequest, type: :model do
  describe '#calculate_changes' do
    let(:user) { create(:user) }
    let(:time) { Time.zone.now}
    subject { CreatePromptReportRequest.create(user_id: user.id).calculate_changes(record1, record2) }

    context 'record1 == record2' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { record1 }
      let(:current_uids) { [4, 3, 2, 1]}

      before do
        record1.save!(validate: false)
        allow(record1).to receive(:calc_unfollower_uids).and_return(current_uids)
        allow(record1).to receive(:unfollower_uids).and_return(current_uids)
      end

      it do
        expect(subject[:twitter_user_id]).to match([record1.id, record2.id])
        expect(subject[:followers_count]).to match([record1.follower_uids.size, record2.follower_uids.size])
        expect(subject[:unfollowers_count]).to match([current_uids.size, current_uids.size])
        expect(subject[:removed_uid]).to match([current_uids.first, current_uids.first])
        expect(subject[:unfollowers_changed]).to be_falsey
      end
    end

    context 'record1 != record2' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { build(:twitter_user, uid: user.uid, created_at: time - 1.seconds) }
      let(:previous_uids) { [3, 2, 1]}
      let(:current_uids) { [4, 3, 2, 1]}

      context 'Unfollowers are changed' do
        before do
          record1.save!(validate: false)
          allow(record1).to receive(:calc_unfollower_uids).and_return(previous_uids)
          allow(record1).to receive(:unfollower_uids).and_return(current_uids)
          record2.save!(validate: false)
          allow(record2).to receive(:calc_unfollower_uids).and_return(current_uids)
          allow(record2).to receive(:unfollower_uids).and_return(current_uids) # The #unfollower_uids returns the same value for the same id.
        end

        it do
          expect(subject[:twitter_user_id]).to match([record1.id, record2.id])
          expect(subject[:followers_count]).to match([record1.follower_uids.size, record2.follower_uids.size])
          expect(subject[:unfollowers_count]).to match([previous_uids.size, current_uids.size])
          expect(subject[:removed_uid]).to match([previous_uids.first, current_uids.first])
          expect(subject[:unfollowers_changed]).to be_truthy
        end
      end

      context 'Unfollowers are not changed' do
        before do
          record1.save!(validate: false)
          allow(record1).to receive(:calc_unfollower_uids).and_return(current_uids)
          allow(record1).to receive(:unfollower_uids).and_return(current_uids)
          record2.save!(validate: false)
          allow(record2).to receive(:calc_unfollower_uids).and_return(current_uids)
          allow(record2).to receive(:unfollower_uids).and_return(current_uids)
        end

        it do
          expect(subject[:twitter_user_id]).to match([record1.id, record2.id])
          expect(subject[:followers_count]).to match([record1.follower_uids.size, record2.follower_uids.size])
          expect(subject[:unfollowers_count]).to match([current_uids.size, current_uids.size])
          expect(subject[:removed_uid]).to match([current_uids.first, current_uids.first])
          expect(subject[:unfollowers_changed]).to be_falsey
        end
      end
    end
  end

  describe '#calculate_period' do
    let(:user) { create(:user) }
    let(:time) { Time.zone.now}
    subject { CreatePromptReportRequest.create(user_id: user.id).calculate_period(record_created, record1, record2) }

    context 'There are more than 2 records' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { build(:twitter_user, uid: user.uid, created_at: time - 1.seconds) }

      before do
        record1.save!(validate: false)
        record2.save!(validate: false)
      end

      context 'New record is created' do
        let(:record_created) { true }
        it { is_expected.to match(start: record1.created_at, end: record2.created_at) }
      end

      context 'New record is NOT created' do
        let(:record_created) { false }
          it do
            freeze_time do
              is_expected.to match(start: record2.created_at, end: Time.zone.now)
            end
        end
      end
    end

    context 'There is one record' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { build(:twitter_user, uid: user.uid, created_at: time - 1.seconds) }

      before do
        record2.save!(validate: false)
      end

      context 'New record is created' do
        let(:record_created) { true }
        it do
          freeze_time do
            is_expected.to match(start: record2.created_at, end: record2.created_at)
          end
        end
      end

      context 'New record is NOT created' do
        let(:record_created) { false }
        it do
          freeze_time do
            is_expected.to match(start: record2.created_at, end: Time.zone.now)
          end
        end
      end
    end

    context 'There is no records' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { build(:twitter_user, uid: user.uid, created_at: time - 1.seconds) }

      let(:record_created) { false }
      it do
        expect { subject }.to raise_error(RuntimeError, 'There are no records.')
      end
    end
  end

  describe '#too_many_errors?' do
    let(:user) { create(:user) }
    subject { CreatePromptReportRequest.create(user_id: user.id) }

    before { CreatePromptReportLog.create_by(request: subject) }

    it { expect(subject.too_many_errors?).to be_falsey }

    context 'There are 2 error logs' do
      before do
        2.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it { expect(subject.too_many_errors?).to be_falsey }
    end

    context 'There are more than 3 error logs' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it { expect(subject.too_many_errors?).to be_truthy }
    end

    context 'There are more than 3 error logs, but error_class is empty' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: '', error_message: "I'm an error") }
      end
      it { expect(subject.too_many_errors?).to be_falsey }
    end
  end
end
