require 'rails_helper'

RSpec.describe CreatePeriodicReportRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user: user) }

  describe '#perform!' do
    subject { request.perform! }
    before do
      allow(request).to receive(:build_report_options).and_return('options')
    end
    it do
      expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, 'options').and_return('jid')
      subject
    end

    context 'check_credentials == true' do
      before { request.check_credentials = true }
      it do
        expect(request).to receive(:verify_credentials_before_starting?).and_return(false)
        subject
      end
    end

    context 'check_interval == true' do
      before { request.check_interval = true }
      it do
        expect(request).to receive(:check_interval_before_starting?).and_return(false)
        subject
      end
    end

    context 'check_following_status == true' do
      before { request.check_following_status = true }
      it do
        expect(request).to receive(:check_following_status_before_starting?).and_return(false)
        subject
      end
    end

    context 'check_allotted_messages_count == true' do
      before { request.check_allotted_messages_count = true }
      it do
        expect(request).to receive(:check_allotted_messages_count_before_starting?).and_return(false)
        subject
      end
    end

    context 'check_twitter_user == true' do
      before { request.check_twitter_user = true }
      it do
        expect(request).to receive(:create_new_twitter_user_record)
        subject
      end
    end
  end

  describe '#verify_credentials_before_starting?' do
    let(:client) { double('client') }
    subject { request.verify_credentials_before_starting? }
    before { allow(user).to receive(:api_client).and_return(client) }
    it do
      expect(client).to receive(:verify_credentials)
      subject
    end
  end

  describe '#check_following_status_before_starting?' do
    subject { request.check_following_status_before_starting? }

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

  describe '#check_allotted_messages_count_before_starting?' do
    subject { request.check_allotted_messages_count_before_starting? }

    before do
      allow(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received?).
          with(user.uid).and_return(true)
      allow(GlobalSendDirectMessageCountByUser).to receive_message_chain(:new, :count).
          with(user.uid).and_return(send_count)
    end

    context 'sending count is less than or equal to 3' do
      let(:send_count) { 3 }
      it do
        expect(CreatePeriodicReportMessageWorker).not_to receive(:perform_async)
        subject
      end
    end

    context 'else' do
      let(:send_count) { 4 }
      it do
        expect(CreatePeriodicReportMessageWorker).to receive(:perform_async).with(user.id, sending_soft_limited: true)
        subject
      end
    end
  end

  describe '#check_interval_before_starting?' do
    subject { request.check_interval_before_starting? }
    it do
      expect(described_class).to receive(:interval_too_short?).
          with(include_user_id: request.user_id, reject_id: request.id).and_return(true)
      subject
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

  describe '.interval_too_short?' do
    shared_context 'record exists' do
      before { create(:create_periodic_report_request, user_id: user.id, finished_at: time, created_at: time) }
    end

    subject { described_class.interval_too_short?(include_user_id: user.id, reject_id: nil) }

    context 'first request' do
      it { is_expected.to be_falsey }
    end

    context 'recently finished' do
      include_context 'record exists'
      let(:time) { 20.minutes.ago }
      it { is_expected.to be_truthy }
    end

    context 'finished a long time ago' do
      include_context 'record exists'
      let(:time) { 3.hours.ago }
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
