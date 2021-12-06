require 'rails_helper'

RSpec.describe CreatePeriodicReportRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user: user) }

  describe '#append_status' do
    subject { request.append_status('text') }
    it do
      subject
      expect(request.status).to eq('text')
    end
  end

  describe '#perform!' do
    subject { request.perform! }

    it do
      expect(request).to receive(:validate_report!).and_return(true)
      expect(request).to receive(:create_new_twitter_user_record)
      expect(request).to receive(:send_report!)
      subject
    end

    context 'validation is failed' do
      before { allow(request).to receive(:validate_report!).and_return(false) }
      it do
        expect(request).not_to receive(:send_report?)
        subject
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
    let(:validator) { PeriodicReportValidator.new(request) }
    subject { request.validate_report!(validator) }

    context 'check_credentials == true' do
      before { request.check_credentials = true }
      it do
        expect(validator).to receive(:validate_credentials!)
        subject
      end
    end

    context 'check_interval == true' do
      before { request.check_interval = true }
      it do
        expect(validator).to receive(:validate_interval!)
        subject
      end
    end

    context 'check_following_status == true' do
      before { request.check_following_status = true }
      it do
        expect(validator).to receive(:validate_following_status!)
        subject
      end
    end

    context 'check_allotted_messages_count == true' do
      before { request.check_allotted_messages_count = true }
      it do
        expect(validator).to receive(:validate_messages_count!)
        subject
      end
    end

    context 'check_web_access == true' do
      before { request.check_web_access = true }
      it do
        expect(validator).to receive(:validate_web_access!)
        subject
      end
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
        CreateTwitterUserRequest::Unauthorized,
        CreateTwitterUserRequest::TooShortCreateInterval,
        CreateTwitterUserRequest::TooLittleFriends,
        CreateTwitterUserRequest::SoftSuspended,
        CreateTwitterUserRequest::TemporarilyLocked,
        CreateTwitterUserRequest::NotChanged,
    ].each do |error|
      context "#{error} is raised" do
        before { allow(CreateTwitterUserTask).to receive(:new).and_raise(error) }
        it do
          expect(Airbag).to receive(:info).with(instance_of(String))
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
          expect(Airbag).to receive(:warn).with(instance_of(String))
          subject
        end
      end
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
end

RSpec.describe CreatePeriodicReportRequest::ReportOptionsBuilder, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePeriodicReportRequest.create(user_id: user.id) }
  let(:instance) { described_class.new(request) }
  describe '#build' do
    subject { instance.build }
    it { is_expected.to be_truthy }
  end
end
