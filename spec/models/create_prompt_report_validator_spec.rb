require 'rails_helper'

RSpec.describe CreatePromptReportValidator, type: :model do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
  let(:validator) { described_class.new(request: request) }

  describe '#validate!' do
    let(:notification_setting) { NotificationSetting.new(user: user) }
    let(:fetched_user) { {id: 1, screen_name: 'sn'} }
    let(:twitter_user) { create(:twitter_user) }
    subject { validator.validate! }

    before do
      allow(validator).to receive(:user).and_return(user)
      allow(user).to receive(:notification_setting).and_return(notification_setting)
      allow(validator).to receive(:fetch_user).and_return(fetched_user)
      allow(TwitterUser).to receive(:exists?).with(uid: user.uid).and_return(true)
      allow(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(twitter_user)
    end

    it do
      expect(validator).to receive(:credentials_verified?).and_return(true)
      expect(validator).to receive(:too_many_errors?).and_return(false)
      expect(notification_setting).to receive(:enough_permission_level?).and_return(true)
      expect(validator).to receive(:too_short_request_interval?).and_return(false)
      expect(user).to receive(:authorized?).and_return(true)
      expect(notification_setting).to receive(:dm_enabled?).and_return(true)
      expect(notification_setting).to receive(:prompt_report_interval_ok?).and_return(true)
      expect(validator).to receive(:suspended?).and_return(false)
      expect(SearchLimitation).to receive(:limited?).with(fetched_user, signed_in: true).and_return(false)
      expect(validator).to receive(:blocked?).and_return(false)

      expect(SearchLimitation).to receive(:limited?).with(twitter_user, signed_in: true).and_return(false)
      expect(twitter_user).to receive(:no_need_to_import_friendships?).and_return(false)
      expect(user).to receive(:active_access?).with(CreatePromptReportRequest::ACTIVE_DAYS).and_return(true)

      subject
    end
  end

  describe '#credentials_verified?' do
    let(:client) { double('Client') }
    subject { validator.credentials_verified? }

    before do
      allow(validator).to receive_message_chain(:client, :twitter).and_return(client)
    end

    it do
      expect(client).to receive(:verify_credentials).and_return(true)
      is_expected.to be_truthy
    end

    context 'The client raises Twitter::Error::Unauthorized' do
      before do
        allow(validator).to receive_message_chain(:client, :twitter).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
      end
      it do
        is_expected.to be_falsey
      end
    end

    context 'The client raises RuntimeError' do
      before do
        allow(validator).to receive_message_chain(:client, :twitter).and_raise('Anything')
      end
      it do
        expect { subject }.to raise_error(CreatePromptReportRequest::Unknown)
      end
    end
  end

  describe '#too_many_errors?' do
    let(:sorted_set) { TooManyErrorsUsers.new }
    subject { validator.too_many_errors? }

    before { validator.instance_variable_set(:@too_many_errors_users, sorted_set) }

    it do
      expect(CreatePromptReportLog).to receive_message_chain(:recent_error_logs, :pluck).
          with(user_id: user.id, request_id: request.id).with(:error_class).and_return('Hello')
      expect(validator).to receive(:meet_requirements_for_too_many_errors?).with('Hello')
      is_expected.to be_falsey
    end

    context 'meet_requirements_for_too_many_errors? == true' do
      before do
        allow(validator).to receive(:meet_requirements_for_too_many_errors?).with(any_args).and_return(true)
      end
      it do
        expect(sorted_set).to receive(:add).with(user.id).and_call_original
        is_expected.to be_truthy
      end
    end

    context 'meet_requirements_for_too_many_errors? == false' do
      before do
        allow(validator).to receive(:meet_requirements_for_too_many_errors?).with(any_args).and_return(false)
      end
      it do
        expect(sorted_set).not_to receive(:add)
        is_expected.to be_falsey
      end
    end
  end

  describe '#meet_requirements_for_too_many_errors?' do
    subject { validator.meet_requirements_for_too_many_errors?(errors) }

    context 'There is a error' do
      let(:errors) { %w(Error) }
      it { is_expected.to be_falsey }
    end

    context 'There are 2 errors' do
      let(:errors) { %w(Error Error) }
      it { is_expected.to be_falsey }
    end

    context 'There are 3 errors' do
      let(:errors) { %w(Error Error Error) }
      it { is_expected.to be_truthy }
    end

    context 'There are 3 errors, but all values are empty' do
      let(:errors) { ['', '', ''] }
      it { is_expected.to be_falsey }
    end
  end

  describe '#too_short_request_interval?' do
    subject { validator.too_short_request_interval? }
    before { CreatePromptReportRequest.create!(user_id: user.id) }
    it { is_expected.to be_truthy }
  end

  describe '#suspended?' do
    subject { validator.suspended? }
    before { allow(validator).to receive(:fetch_user).and_return({suspended: true}) }
    it { is_expected.to be_truthy }
  end

  describe '#blocked?' do
    let(:fetched_user) { {id: 1, screen_name: 'sn'} }
    subject { validator.blocked? }

    before { allow(validator).to receive(:fetch_user).and_return(fetched_user) }

    context 'BlockedUser.exists? == true' do
      before { allow(BlockedUser).to receive(:exists?).with(any_args).and_return(true) }
      it { is_expected.to be_truthy }
    end

    context 'BlockedUser.exists? == false' do
      before do
        allow(BlockedUser).to receive(:exists?).with(any_args).and_return(false)
        allow(validator).to receive_message_chain(:client, :blocked_ids, :include?).with(User::EGOTTER_UID).and_return(true)
      end
      it do
        expect(CreateBlockedUserWorker).to receive(:perform_async).with(1, 'sn')
        is_expected.to be_truthy
      end
    end
  end

  describe '#fetch_user' do
    let(:client) { double('Client') }
    let(:fetched_user) { {id: 1, screen_name: 'sn'} }
    subject { validator.fetch_user }

    before { allow(validator).to receive(:client).and_return(client) }
    it do
      expect(client).to receive(:user).with(user.uid).and_return(fetched_user)
      is_expected.to match(fetched_user)
    end

    context '#client.user raises Twitter::Error::Unauthorized' do
      before do
        allow(client).to receive(:user).with(user.uid).and_raise(Twitter::Error::Unauthorized, 'Invalid or expired token.')
      end
      it { expect { subject }.to raise_error(CreatePromptReportRequest::Unauthorized) }
    end
  end

  describe '#client' do
    let(:client) { double('Client') }
    subject { validator.client }
    before { allow(validator).to receive(:user).and_return(user) }
    it do
      expect(user).to receive(:api_client).and_return(client)
      is_expected.to eq(client)
    end
  end
end
