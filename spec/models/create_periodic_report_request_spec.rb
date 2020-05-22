require 'rails_helper'

RSpec.describe CreatePeriodicReportRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user: user) }

  describe '#perform!' do
    subject { request.perform! }

    it do
      expect(request).to receive(:validate_report!).and_return(true)
      expect(request).to receive(:send_report!)
      subject
    end

    context 'check_twitter_user == true' do
      before { request.check_twitter_user = true }
      it do
        expect(request).to receive(:create_new_twitter_user_record)
        subject
      end
    end

    context 'validation is failed' do
      before { allow(request).to receive(:validate_report!).and_return(false) }
      it do
        expect(request).not_to receive(:send_report?)
        subject
      end
    end
  end

  describe '#send_report?' do
    subject { request.send_report? }

    it { is_expected.to be_truthy }

    context 'send_only_if_changed is false' do
      before { request.send_only_if_changed = false }
      it { is_expected.to be_truthy }
    end

    context 'send_only_if_changed is true' do
      before { request.send_only_if_changed = true }

      context 'report_options_builder.unfollowers_increased? is false' do
        before { allow(request).to receive_message_chain(:report_options_builder, :unfollowers_increased?).and_return(false) }
        it { is_expected.to be_falsey }
      end

      context 'report_options_builder.unfollowers_increased? is true' do
        before { allow(request).to receive_message_chain(:report_options_builder, :unfollowers_increased?).and_return(true) }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_report!' do
    subject { request.send_report! }
    before { allow(request).to receive_message_chain(:report_options_builder, :build).and_return('options') }
    it do
      expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, 'options').and_return('jid')
      subject
    end
  end

  describe '#validate_report!' do
    shared_examples 'request is validated' do
      it do
        expect(validator_class).to receive_message_chain(:new, :validate_and_deliver!).with(request).with(no_args)
        subject
      end
    end

    subject { request.validate_report! }

    context 'check_credentials == true' do
      let(:validator_class) { described_class::CredentialsValidator }
      before { request.check_credentials = true }
      include_examples 'request is validated'
    end

    context 'check_interval == true' do
      let(:validator_class) { described_class::IntervalValidator }
      before { request.check_interval = true }
      include_examples 'request is validated'
    end

    context 'check_following_status == true' do
      let(:validator_class) { described_class::FollowingStatusValidator }
      before { request.check_following_status = true }
      include_examples 'request is validated'
    end

    context 'check_allotted_messages_count == true' do
      let(:validator_class) { described_class::AllottedMessagesCountValidator }
      before { request.check_allotted_messages_count = true }
      include_examples 'request is validated'
    end
  end

  describe '#create_new_twitter_user_record' do
    let(:task) { double('task') }
    subject { request.create_new_twitter_user_record }

    it do
      expect(CreateTwitterUserRequest).to receive(:create).
          with(requested_by: described_class, user_id: user.id, uid: user.uid).and_return('request')
      expect(CreateTwitterUserTask).to receive(:new).with('request').and_return(task)
      expect(task).to receive(:start!)
      subject
    end

    [
        CreateTwitterUserRequest::TooShortCreateInterval,
        CreateTwitterUserRequest::NotChanged
    ].each do |error|
      context "#{error} is raised" do
        before { allow(CreateTwitterUserTask).to receive(:new).and_raise(error) }
        it do
          expect(request.logger).to receive(:info).with(instance_of(String))
          subject
        end
      end
    end

    [
        RuntimeError
    ].each do |error|
      context "#{error} is raised" do
        before { allow(CreateTwitterUserTask).to receive(:new).and_raise(error) }
        it do
          expect(request.logger).to receive(:warn).with(instance_of(String))
          subject
        end
      end
    end
  end

  describe '.next_creation_time' do
    let(:request) { build(:create_periodic_report_request, user_id: user.id) }

    shared_context 'record exists' do
      before do
        request.save!
        allow(described_class).to receive(:fetch_last_request).
            with(include_user_id: user.id, reject_id: nil).and_return(request)
      end
    end

    subject { described_class.next_creation_time(user.id) }

    context 'first request' do
      it do
        freeze_time do
          is_expected.to eq(Time.zone.now + described_class::SHORT_INTERVAL + 1.second)
        end
      end
    end

    context 'record exists' do
      include_context 'record exists'
      let(:time) { 1.day.ago }
      before { request.update!(finished_at: time) }
      it { is_expected.to be_within(3).of(time + described_class::SHORT_INTERVAL + 1.second) }
    end
  end

  describe '.fetch_last_request' do
    let(:request) { build(:create_periodic_report_request, user_id: user.id) }
    let(:include_user_id) { user.id }
    let(:reject_id) { nil }

    shared_context 'record exists' do
      before do
        request.save!
        allow(described_class).to receive(:correctly_completed).and_return(described_class.where(id: request.id))
      end
    end

    subject { described_class.fetch_last_request(include_user_id: include_user_id, reject_id: reject_id) }

    context 'first request' do
      it { is_expected.to be_nil }
    end

    context 'record exists' do
      include_context 'record exists'
      it { is_expected.to satisfy { |result| result.id == request.id } }
    end

    context 'reject_id is specified' do
      include_context 'record exists'
      let(:reject_id) { request.id }
      it { is_expected.to be_nil }
    end
  end

  describe '.interval_too_short?' do
    let(:request) { build(:create_periodic_report_request, user_id: user.id, finished_at: Time.zone.now) }
    shared_context 'record exists' do
      before do
        request.save!
        allow(described_class).to receive(:fetch_last_request).
            with(include_user_id: 'include_user_id', reject_id: 'reject_id').and_return(request)
      end
    end

    subject { described_class.interval_too_short?(include_user_id: 'include_user_id', reject_id: 'reject_id') }

    context 'first request' do
      it { is_expected.to be_falsey }
    end

    context 'recently finished' do
      include_context 'record exists'
      it { is_expected.to be_truthy }
    end

    context 'finished a long time ago' do
      include_context 'record exists'
      before { request.update!(finished_at: 3.hours.ago) }
      it { is_expected.to be_falsey }
    end
  end

  describe '.sufficient_interval?' do
    shared_context 'record exists' do
      before { create(:create_periodic_report_request, user_id: user.id, finished_at: time, created_at: time) }
    end

    subject { described_class.sufficient_interval?(user.id) }

    context 'first request' do
      it { is_expected.to be_truthy }
    end

    context 'recently finished' do
      include_context 'record exists'
      let(:time) { 30.minutes.ago }
      it { is_expected.to be_falsey }
    end

    context 'finished a long time ago' do
      include_context 'record exists'
      let(:time) { 1.day.ago }
      it { is_expected.to be_truthy }
    end
  end
end

RSpec.describe CreatePeriodicReportRequest::CredentialsValidator, type: :model do
  let(:request) { CreatePeriodicReportRequest.create(user_id: 1) }
  let(:instance) { described_class.new(request) }

  describe '#validate!' do
    subject { instance.validate! }
    it do
      expect(request).to receive_message_chain(:user, :api_client, :verify_credentials)
      is_expected.to be_truthy
    end
  end

  describe '#deliver!' do
    subject { instance.deliver! }
    before { allow(instance).to receive(:user_or_egotter_requested_job?).and_return(true) }
    it do
      expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
          with(request.user_id, unauthorized: true).and_return('jid')
      subject
    end
  end
end

RSpec.describe CreatePeriodicReportRequest::IntervalValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePeriodicReportRequest.create(user_id: user.id) }
  let(:instance) { described_class.new(request) }

  describe '#validate!' do
    subject { instance.validate! }
    before do
      allow(CreatePeriodicReportRequest).to receive(:interval_too_short?).
          with(include_user_id: request.user_id, reject_id: request.id).and_return(true)
    end
    it { is_expected.to be_falsey }
  end

  describe '#deliver!' do
    subject { instance.deliver! }
    before { allow(instance).to receive(:user_or_egotter_requested_job?).and_return(true) }

    context 'ScheduledJob exists' do
      before do
        allow(CreatePeriodicReportRequest::ScheduledJob).to receive(:exists?).with(user_id: user.id).and_return(true)
        allow(CreatePeriodicReportRequest::ScheduledJob).to receive(:find_by).with(user_id: user.id).and_return(double('job', jid: 'scheduled_jid'))
      end
      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
            with(request.user_id, scheduled_job_exists: true, scheduled_jid: 'scheduled_jid').and_return('jid')
        subject
      end
    end

    context "ScheduledJob doesn't exist" do
      before do
        allow(CreatePeriodicReportRequest::ScheduledJob).to receive(:exists?).with(user_id: user.id).and_return(false)
      end
      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
            with(request.user_id, scheduled_job_created: true, scheduled_jid: instance_of(String)).and_return('jid')
        subject
      end
    end
  end
end

RSpec.describe CreatePeriodicReportRequest::FollowingStatusValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePeriodicReportRequest.create(user_id: user.id) }
  let(:instance) { described_class.new(request) }

  before { allow(request).to receive(:user).and_return(user) }

  describe '#validate!' do
    subject { instance.validate! }

    context 'EgotterFollower is persisted' do
      before { allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(true) }
      it { is_expected.to be_truthy }
    end

    context 'friendship? returns true' do
      before do
        allow(user).to receive_message_chain(:api_client, :twitter, :friendship?).
            with(user.uid, User::EGOTTER_UID).and_return(true)
      end
      it { is_expected.to be_truthy }
    end

    context 'else' do
      before do
        allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(false)
        allow(user).to receive_message_chain(:api_client, :twitter, :friendship?).
            with(user.uid, User::EGOTTER_UID).and_return(false)
      end
      it { is_expected.to be_falsey }
    end
  end

  describe '#deliver!' do
    subject { instance.deliver! }
    before { allow(instance).to receive(:user_or_egotter_requested_job?).and_return(true) }
    it do
      expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
          with(request.user_id, not_following: true).and_return('jid')
      subject
    end
  end
end

RSpec.describe CreatePeriodicReportRequest::AllottedMessagesCountValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePeriodicReportRequest.create(user_id: user.id) }
  let(:instance) { described_class.new(request) }

  before { allow(request).to receive(:user).and_return(user) }

  describe '#validate!' do
    subject { instance.validate! }

    context 'DM received flag is not set' do
      before { allow(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received?).with(user.uid).and_return(false) }
      it { is_expected.to be_truthy }
    end

    context 'DM received flag is set' do
      before { allow(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received?).with(user.uid).and_return(true) }

      context 'allotted_messages_left? returns true' do
        before { allow(PeriodicReport).to receive(:allotted_messages_left?).with(user, count: 3).and_return(true) }
        it { is_expected.to be_truthy }
      end

      context 'allotted_messages_left? returns false' do
        before { allow(PeriodicReport).to receive(:allotted_messages_left?).with(user, count: 3).and_return(false) }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#deliver!' do
    subject { instance.deliver! }
    it do
      expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).
          with(request.user_id, sending_soft_limited: true).and_return('jid')
      subject
    end
  end
end

RSpec.describe CreatePeriodicReportRequest::ScheduledJob, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePeriodicReportRequest.create(user_id: user.id) }

  describe '.exists?' do
    # It's difficult to test Sidekiq::ScheduledSet because Sidekiq's API does not have a testing mode
  end

  describe '.create' do
    subject { described_class.create(user_id: user.id) }
    before { allow(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id, requested_by: described_class).and_return(request) }
    it do
      expect(described_class::WORKER_CLASS).to receive(:perform_at).
          with(anything, request.id, user_id: user.id, scheduled_request: true).and_return('jid')
      expect(subject.jid).to eq('jid')
    end
  end

  describe '.find_by' do
    # It's difficult to test Sidekiq::ScheduledSet because Sidekiq's API does not have a testing mode
  end
end
