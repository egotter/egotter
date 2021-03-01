require 'rails_helper'

RSpec.describe PeriodicReportValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user: user) }
  let(:instance) { described_class.new(request) }

  describe '#validate_credentials!' do
    subject { instance.validate_credentials! }
    it do
      expect(described_class::CredentialsValidator).to receive_message_chain(:new, :validate_and_deliver!).with(request).with(no_args)
      subject
    end
  end

  describe '#validate_following_status!' do
    subject { instance.validate_following_status! }
    it do
      expect(described_class::FollowingStatusValidator).to receive_message_chain(:new, :validate_and_deliver!).with(request).with(no_args)
      subject
    end
  end

  describe '#validate_interval!' do
    subject { instance.validate_interval! }
    it do
      expect(described_class::IntervalValidator).to receive_message_chain(:new, :validate_and_deliver!).with(request).with(no_args)
      subject
    end
  end

  describe '#validate_messages_count!' do
    subject { instance.validate_messages_count! }
    it do
      expect(described_class::AllottedMessagesCountValidator).to receive_message_chain(:new, :validate_and_deliver!).with(request).with(no_args)
      subject
    end
  end

  describe '#validate_web_access!' do
    subject { instance.validate_web_access! }
    it do
      expect(described_class::WebAccessValidator).to receive_message_chain(:new, :validate_and_deliver!).with(request).with(no_args)
      subject
    end
  end
end

RSpec.describe PeriodicReportValidator::CredentialsValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user_id: user.id) }
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
      expect(CreatePeriodicReportUnauthorizedMessageWorker).to receive(:perform_async).with(request.user_id).and_return('jid')
      subject
    end
  end
end

RSpec.describe PeriodicReportValidator::IntervalValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user_id: user.id) }
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

    it do
      expect(CreatePeriodicReportIntervalTooShortMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end

RSpec.describe PeriodicReportValidator::FollowingStatusValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user_id: user.id) }
  let(:instance) { described_class.new(request) }

  before { allow(request).to receive(:user).and_return(user) }

  describe '#validate!' do
    subject { instance.validate! }

    context 'EgotterFollower is persisted' do
      before { allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(true) }
      it { is_expected.to be_truthy }
    end

    context 'else' do
      before do
        allow(EgotterFollower).to receive(:exists?).with(uid: user.uid).and_return(false)
        allow(user).to receive(:send_periodic_report_even_though_not_following?).and_return(false)
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
      expect(CreatePeriodicReportNotFollowingMessageWorker).to receive(:perform_async).
          with(request.user_id).and_return('jid')
      subject
    end
  end
end

RSpec.describe PeriodicReportValidator::AllottedMessagesCountValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user_id: user.id) }
  let(:instance) { described_class.new(request) }

  before { allow(request).to receive(:user).and_return(user) }

  describe '#validate!' do
    subject { instance.validate! }

    context 'messages are not allotted' do
      before { allow(PeriodicReport).to receive(:messages_allotted?).with(user).and_return(false) }
      it { is_expected.to be_truthy }
    end

    context 'messages are allotted' do
      before { allow(PeriodicReport).to receive(:messages_allotted?).with(user).and_return(true) }

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
      expect(CreatePeriodicReportAllottedMessagesNotEnoughMessageWorker).to receive(:perform_async).with(request.user_id).and_return('jid')
      subject
    end
  end
end

RSpec.describe PeriodicReportValidator::WebAccessValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_periodic_report_request, user_id: user.id) }
  let(:instance) { described_class.new(request) }

  before { allow(request).to receive(:user).and_return(user) }

  describe '#validate!' do
    subject { instance.validate! }

    context 'web_access is limited' do
      before { allow(PeriodicReport).to receive(:access_interval_too_long?).with(user).and_return(true) }
      it { is_expected.to be_falsey }
    end

    context 'web_access is not limited' do
      before { allow(PeriodicReport).to receive(:access_interval_too_long?).with(user).and_return(false) }
      it { is_expected.to be_truthy }
    end
  end

  describe '#deliver!' do
    subject { instance.deliver! }
    it do
      expect(CreatePeriodicReportAccessIntervalTooLongMessageWorker).to receive(:perform_async).with(request.user_id).and_return('jid')
      subject
    end
  end
end
