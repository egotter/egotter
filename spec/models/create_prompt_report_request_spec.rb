require 'rails_helper'

RSpec.describe CreatePromptReportRequest, type: :model do
  describe '#calculate_period' do
    let(:user) { create(:user) }
    let(:time) { Time.zone.now }
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
    let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
    let(:sorted_set) { TooManyErrorsUsers.new }
    subject { request.too_many_errors? }

    before do
      CreatePromptReportLog.create_by(request: request)
      request.instance_variable_set(:@too_many_errors_users, sorted_set)
    end

    context 'There is a error log' do
      before do
        1.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end

    context 'There are 2 error logs' do
      before do
        2.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end

    context 'There are 3 error logs' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it do
        expect(sorted_set).to receive(:add).with(user.id).and_call_original
        is_expected.to be_truthy
      end
    end

    context 'There are 3 error logs, but they are outdated' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error', created_at: 1.day.ago - 1) }
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end

    context 'There are 3 error logs, but the error_class is CreatePromptReportRequest::TooManyErrors' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'CreatePromptReportRequest::TooManyErrors') }
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end

    context 'There are 3 error logs, but error_class is empty' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: '', error_message: "I'm an error") }
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end

    context 'There is a success log between 3 error logs.' do
      before do
        now = Time.zone.now
        CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error', created_at: now - 4.seconds)
        CreatePromptReportLog.create!(user_id: user.id, error_class: '',      created_at: now - 3.seconds)
        CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error', created_at: now - 2.seconds)
        CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error', created_at: now - 1.second)
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end
  end

  describe '#fetch_user' do
    let(:user) { create(:user) }
    let(:client) { double('Client') }
    let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
    subject { request.send(:fetch_user) }

    before do
      allow(request).to receive(:client).with(no_args).and_return(client)
      allow(client).to receive(:user).with(user.uid).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
    end

    it { expect { subject }.to raise_error(described_class::Unauthorized) }
  end
end

RSpec.describe CreatePromptReportRequest::ChangesBuilder, type: :model do
  describe '#build' do
    let(:user) { create(:user) }
    let(:time) { Time.zone.now }
    subject { described_class.new(record1, record2, record_created: record_created).build }

    let(:result) do
      {
          twitter_user_id: [record1.id, record2.id],
          followers_count: [record1.follower_uids.size, record2.follower_uids.size],
          unfollowers_count: [previous_uids.size, current_uids.size],
          removed_uid: [previous_uids.first, current_uids.first],
          unfollowers_changed: changed,
      }
    end

    context 'record1 == record2 and record_created == true' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { record1 }
      let(:record_created) { true }
      let(:previous_uids) { [4, 3, 2, 1] }
      let(:current_uids) { previous_uids }
      let(:changed) { false }

      before do
        record1.save!(validate: false)
        allow(record1).to receive(:calc_unfollower_uids).and_return(current_uids)
        allow(record1).to receive(:unfollower_uids).and_return(current_uids)
      end

      it { expect(subject).to match(result) }
    end

    context 'record1 == record2 and record_created == false' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { record1 }
      let(:record_created) { false }
      let(:previous_uids) { [4, 3, 2, 1] }
      let(:current_uids) { previous_uids }
      let(:changed) { false }

      before do
        record1.save!(validate: false)
        allow(record1).to receive(:calc_unfollower_uids).and_return(current_uids)
        allow(record1).to receive(:unfollower_uids).and_return(current_uids)
      end

      it { expect(subject).to match(result) }
    end

    context 'record1 != record2 and record_created == true' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { build(:twitter_user, uid: user.uid, created_at: time - 1.seconds) }
      let(:record_created) { true }

      before do
        record1.save!(validate: false)
        allow(record1).to receive(:calc_unfollower_uids).and_return(previous_uids)
        allow(record1).to receive(:unfollower_uids).and_return(current_uids)

        record2.save!(validate: false)
        allow(record2).to receive(:calc_unfollower_uids).and_return(current_uids)
        allow(record2).to receive(:unfollower_uids).and_return(current_uids) # The #unfollower_uids returns the same value for the same id.
      end

      context 'The number of previous_uids is more than current_uids' do
        context 'Added to the beginning of the array' do
          let(:previous_uids) { [3, 2, 1] }
          let(:current_uids) { [2, 1] }
          let(:changed) { true } # That's impossible, but it's changed.
          it { expect(subject).to match(result) }
        end

        context 'Added to the end of the array' do
          let(:previous_uids) { [3, 2, 1] }
          let(:current_uids) { [3, 2] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end
      end

      context 'The number of previous_uids is less than current_uids' do
        context 'Added to the beginning of the array' do
          let(:previous_uids) { [2, 1] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { true }
          it { expect(subject).to match(result) }
        end

        context 'Added to the end of the array' do
          let(:previous_uids) { [2, 1] }
          let(:current_uids) { [2, 1, 0] }
          let(:changed) { false } # That's impossible, but it's not changed.
          it { expect(subject).to match(result) }
        end
      end

      context 'The number of previous_uids is the same as the number of current_uids' do
        context 'The beginning of the array is changed' do
          let(:previous_uids) { [0, 2, 1] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { true } # That's impossible, but it's changed.
          it { expect(subject).to match(result) }
        end

        context 'The end of the array is changed' do
          let(:previous_uids) { [3, 2, 0] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { true } # That's impossible, but it's changed.
          it { expect(subject).to match(result) }
        end

        context 'The previous_uids perfectly match the current_uids' do
          let(:previous_uids) { [3, 2, 1] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end
      end
    end

    context 'record1 != record2 and record_created == false' do
      let(:record1) { build(:twitter_user, uid: user.uid, created_at: time - 2.seconds) }
      let(:record2) { build(:twitter_user, uid: user.uid, created_at: time - 1.seconds) }
      let(:record_created) { false }

      before do
        record1.save!(validate: false)
        allow(record1).to receive(:calc_unfollower_uids).and_return(previous_uids)
        allow(record1).to receive(:unfollower_uids).and_return(current_uids)

        record2.save!(validate: false)
        allow(record2).to receive(:calc_unfollower_uids).and_return(current_uids)
        allow(record2).to receive(:unfollower_uids).and_return(current_uids) # The #unfollower_uids returns the same value for the same id.
      end

      context 'The number of previous_uids is more than current_uids' do
        context 'Added to the beginning of the array' do
          let(:previous_uids) { [3, 2, 1] }
          let(:current_uids) { [2, 1] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end

        context 'Added to the end of the array' do
          let(:previous_uids) { [3, 2, 1] }
          let(:current_uids) { [3, 2] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end
      end

      context 'The number of previous_uids is less than current_uids' do
        context 'Added to the beginning of the array' do
          let(:previous_uids) { [2, 1] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end

        context 'Added to the end of the array' do
          let(:previous_uids) { [2, 1] }
          let(:current_uids) { [2, 1, 0] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end
      end

      context 'The number of previous_uids is the same as the number of current_uids' do
        context 'The beginning of the array is changed' do
          let(:previous_uids) { [0, 2, 1] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end

        context 'The end of the array is changed' do
          let(:previous_uids) { [3, 2, 0] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end

        context 'The previous_uids perfectly match the current_uids' do
          let(:previous_uids) { [3, 2, 1] }
          let(:current_uids) { [3, 2, 1] }
          let(:changed) { false }
          it { expect(subject).to match(result) }
        end
      end
    end
  end
end
