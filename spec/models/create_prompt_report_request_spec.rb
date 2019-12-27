require 'rails_helper'

RSpec.describe CreatePromptReportRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create!(user_id: user.id) }

  describe '.interval_ng_user_ids' do
    let(:user2) { create(:user) }
    subject { described_class.interval_ng_user_ids }
    before do
      CreatePromptReportRequest.create!(user_id: user.id)
      CreatePromptReportRequest.create!(user_id: user2.id, created_at: (described_class::PROCESS_REQUEST_INTERVAL + 1).ago)
    end
    it { is_expected.to satisfy { |ids| ids.include?(user.id) && ids.exclude?(user2.id) } }
  end

  describe '#perform!' do
    let(:prompt_report) { create(:prompt_report, user_id: user.id) }
    let(:report_options_builder) { CreatePromptReportRequest::ReportOptionsBuilder.new(user, self, true, prompt_report) }
    subject { request.perform!(true) }

    before do
      user.create_notification_setting!
      allow(request).to receive(:error_check!)
      allow(TwitterUser).to receive(:exists?).with(uid: user.uid).and_return(true)
      allow(report_options_builder).to receive(:build).and_return('ok')
    end

    it do
      expect(request).to receive(:send_starting_confirmation_message!).and_return(prompt_report)
      expect(CreatePromptReportRequest::ReportOptionsBuilder).to receive(:new).with(user, request, true, prompt_report.id).and_return(report_options_builder)
      expect(CreatePromptReportMessageWorker).to receive(:perform_async).with(user.id, 'ok')
      subject
    end

    context '#report_if_changed is checked' do
      before { user.notification_setting.update!(report_if_changed: true) }

      it do
        expect(request).not_to receive(:send_starting_confirmation_message!)
        expect(CreatePromptReportRequest::ReportOptionsBuilder).to receive(:new).with(user, request, true, nil).and_return(report_options_builder)
        subject
      end

      context 'kind is :you_are_removed' do
        before { request.kind = :you_are_removed }
        it do
          expect(CreatePromptReportMessageWorker).to receive(:perform_async).with(user.id, 'ok')
          expect(CreatePromptReportRequest::ReportOptionsBuilder).to receive(:new).with(user, request, true, nil).and_return(report_options_builder)
          subject
        end
      end

      context 'kind is :not_changed' do
        before { request.kind = :not_changed }
        it do
          expect(CreatePromptReportMessageWorker).not_to receive(:perform_async)
          expect(CreatePromptReportRequest::ReportOptionsBuilder).to receive(:new).with(user, request, true, nil).and_return(report_options_builder)
          subject
        end
      end
    end
  end

  describe '#error_check!' do
    subject { request.error_check! }
    it do
      expect(CreatePromptReportValidator).to receive_message_chain(:new, :validate!).with(request: request).with(no_args)
      is_expected.to be_truthy
      expect(request.instance_variable_get(:@error_check)).to be_truthy
    end
  end

  describe '#send_starting_confirmation_message!' do
    let(:prompt_report) { PromptReport.new(user_id: user.id) }
    subject { request.send_starting_confirmation_message! }
    it do
      expect(PromptReport).to receive(:new).with(user_id: user.id).and_return(prompt_report)
      expect(prompt_report).to receive(:deliver_starting_message!)
      is_expected.to eq(prompt_report)
    end

    context 'PromptReport::StartingFailed is raised' do
      let(:exception) { PromptReport::StartingFailed.new('message') }
      before { allow(PromptReport).to receive(:new).with(any_args).and_raise(exception) }
      it { expect { subject }.to raise_error(described_class::StartingConfirmationFailed, 'message') }
    end
  end
end

RSpec.describe CreatePromptReportRequest::ReportOptionsBuilder, type: :model do
  let(:user) { create(:user) }
  let(:record1) { build(:twitter_user, uid: user.uid, created_at: 1.minute.ago) }
  let(:record2) { build(:twitter_user, uid: user.uid, created_at: 1.second.ago) }

  before do
    record1.save!(validate: false)
    record2.save!(validate: false)
  end

  describe '#build' do
    let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
    let(:builder) { described_class.new(user, request, true, 2) }
    let(:changes_builder) { CreatePromptReportRequest::ChangesBuilder.new(record1, record2, record_created: true) }
    let(:period_builder) { CreatePromptReportRequest::PeriodBuilder.new(true, record1, record2) }
    subject { builder.build }

    it do
      expect(builder).to receive(:latest).and_return(record2)
      expect(builder).to receive(:second_latest).and_return(record1)

      expect(CreatePromptReportRequest::ChangesBuilder).to receive(:new).with(record1, record2, record_created: true).and_return(changes_builder)
      expect(CreatePromptReportRequest::PeriodBuilder).to receive(:new).with(true, record1, record2).and_return(period_builder)

      expect(changes_builder).to receive(:build).and_return(a: 1, unfollowers_changed: true)
      expect(period_builder).to receive(:build).and_return(b: 2)

      values = {
          changes_json: {a: 1, unfollowers_changed: true, period: {b: 2}}.to_json,
          previous_twitter_user_id: record1.id,
          current_twitter_user_id: record2.id,
          create_prompt_report_request_id: request.id,
          kind: :you_are_removed,
          prompt_report_id: 2,
      }
      is_expected.to match(values)
    end
  end

  describe '#latest' do
    let(:builder) { described_class.new(user, nil, nil, nil) }
    subject { builder.latest }
    it { is_expected.to eq(record2) }
  end

  describe '#second_latest' do
    let(:builder) { described_class.new(user, nil, nil, nil) }
    subject { builder.second_latest(record2.id) }
    it { is_expected.to eq(record1) }
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

RSpec.describe CreatePromptReportRequest::PeriodBuilder, type: :model do
  describe '#build' do
    let(:user) { create(:user) }
    let(:time) { Time.zone.now }
    subject { described_class.new(record_created, record1, record2).build }

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
end
