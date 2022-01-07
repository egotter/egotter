require 'rails_helper'

RSpec.describe PeriodicReport do
  let(:user) { create(:user, with_credential_token: true) }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '.periodic_message' do
    let(:options) { {} }
    subject { described_class.periodic_message(user.id, options) }

    context 'periodic_report_id is passed' do
      let(:report) { create(:periodic_report, user: user, properties: {empty: true}) }
      let(:options) { {periodic_report_id: report.id} }
      before do
        allow(described_class).to receive(:find).with(report.id).and_return(report)
        allow(described_class).to receive(:build_report_message).with(user, 'token', {empty: true}).and_return('message')
      end
      it { is_expected.to be_truthy }
    end
  end

  describe '.build_report_message' do
    let(:request) { double('request', id: 1) }
    let(:start_date) { 1.day.ago }
    let(:end_date) { Time.zone.now }
    let(:unfriends) { %w(a b c) }
    let(:total_unfollowers) { %w(x1 y1 z1) }
    let(:options) do
      {
          version: 1,
          request_id: request.id,
          start_date: start_date,
          end_date: end_date,
          unfriends: unfriends,
          unfollowers: unfollowers,
          total_unfollowers: total_unfollowers,
          account_statuses: [],
      }
    end

    subject { described_class.build_report_message(user, 'token', options) }

    context 'unfollowers.size is greater than 1' do
      let(:unfollowers) { %w(x y z) }
      it { is_expected.to be_truthy }
    end

    context 'unfollowers.size is 0' do
      let(:unfollowers) { [] }
      it { is_expected.to be_truthy }

      context 'followers count decreased' do
        before do
          options.merge!(first_followers_count: 2)
          options.merge!(last_followers_count: 1)
        end
        it do
          expect(described_class).to receive(:followers_count_decreased?).with(2, 1).and_call_original
          is_expected.to be_truthy
        end
      end
    end
  end

  describe '.periodic_push_message' do
    let(:options) { {} }
    subject { described_class.periodic_push_message(user.id, options) }

    context 'periodic_report_id is passed' do
      let(:report) { create(:periodic_report, user: user, properties: {empty: true}) }
      let(:options) { {periodic_report_id: report.id} }
      before do
        allow(described_class).to receive(:find).with(report.id).and_return(report)
        allow(described_class).to receive(:build_push_report_message).with(user, {empty: true}).and_return('message')
      end
      it { is_expected.to be_truthy }
    end

    context 'periodic_report_id is not passed' do
      before do
        allow(described_class).to receive(:build_push_report_message).with(user, options).and_return('message')
      end
      it { is_expected.to be_truthy }
    end
  end

  describe '.build_push_report_message' do
    let(:request) { double('request', id: 1) }
    let(:start_date) { 1.day.ago }
    let(:end_date) { Time.zone.now }
    let(:unfriends) { %w(a b c) }
    let(:options) do
      {
          request_id: request.id,
          start_date: start_date,
          end_date: end_date,
          unfriends: unfriends,
          unfollowers: unfollowers,
      }
    end

    subject { described_class.build_push_report_message(user, options) }

    context 'unfollowers.size is greater than 1' do
      let(:unfollowers) { %w(x y z) }
      it { is_expected.to be_truthy }
    end

    context 'unfollowers.size is 1' do
      let(:unfollowers) { [] }
      it { is_expected.to be_truthy }
    end
  end

  describe '.remind_reply_message' do
    subject { described_class.remind_reply_message }
    it { is_expected.to be_truthy }
  end

  describe '.allotted_messages_will_expire_message' do
    subject { described_class.allotted_messages_will_expire_message(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '.allotted_messages_not_enough_message' do
    subject { described_class.allotted_messages_not_enough_message(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '.access_interval_too_long_message' do
    subject { described_class.access_interval_too_long_message(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '.interval_too_short_message' do
    subject { described_class.interval_too_short_message(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '.request_interval_too_short_message' do
    subject { described_class.request_interval_too_short_message(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '.unauthorized_message' do
    subject { described_class.unauthorized_message }
    it { is_expected.to be_truthy }
  end

  describe '.unregistered_message' do
    subject { described_class.unregistered_message }
    it { is_expected.to be_truthy }
  end

  describe '.not_following_message' do
    subject { described_class.not_following_message(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '.permission_level_not_enough_message' do
    subject { described_class.permission_level_not_enough_message }
    it { is_expected.to be_truthy }
  end

  describe '.restart_requested_message' do
    subject { described_class.restart_requested_message }
    it { is_expected.to be_truthy }
  end

  describe '.stop_requested_message' do
    subject { described_class.stop_requested_message }
    it { is_expected.to be_truthy }
  end

  describe '.pick_period_name' do
    subject { described_class.pick_period_name }
    it { is_expected.to be_truthy }
  end

  describe '.calc_aggregation_period' do
    subject { described_class.calc_aggregation_period(1.day.ago, Time.zone.now) }
    it { is_expected.to be_truthy }
  end

  describe '.calc_followers_count_change' do
    subject { described_class.calc_followers_count_change(1, 2, 3) }
    it { is_expected.to eq('1 - 2') }
  end

  describe '.encrypt_indicator_names' do
    subject { described_class.encrypt_indicator_names(['a', 'b']) }
    it { is_expected.to be_truthy }
  end

  describe '.request_id_text' do
    subject { described_class.request_id_text(user, 1, 'CreateUserRequestedPeriodicReportWorker') }
    before { user.create_periodic_report_setting! }
    it { is_expected.to satisfy { |result| !result.include?('er') } }
  end

  describe '.remaining_ttl_text' do
    subject { described_class.remaining_ttl_text(12.hours) }
    it { is_expected.to be_truthy }
  end

  describe '.worker_context_text' do
    subject { described_class.worker_context_text('CreateUserRequestedPeriodicReportWorker') }
    it { is_expected.to be_truthy }
  end

  describe '.extract_date' do
    let(:time) { 1.day.ago }
    subject { described_class.extract_date('start_date', 'start_date' => time) }
    it { is_expected.to eq(time) }
  end

  describe '.campaign_params' do
    subject { described_class.campaign_params('name') }
    it { is_expected.to be_truthy }
  end

  describe '.timeline_url' do
    subject { described_class.timeline_url(user, {}) }
    it { is_expected.to be_truthy }
  end

  describe '.messages_allotted?' do
    subject { described_class.messages_allotted?(user) }
    it do
      expect(DirectMessageReceiveLog).to receive(:message_received?).with(user.uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '.interval_too_short?' do
    subject { described_class.interval_too_short?(user) }
    before { described_class.create!(user_id: user.id, token: 't', message_id: 'id') }
    it { is_expected.to be_truthy }
  end

  describe '.last_report_time' do
    subject { described_class.last_report_time(user.id) }
    it { is_expected.to be_falsey }
  end

  describe '.next_report_time' do
    subject { described_class.next_report_time(user.id) }
    it { is_expected.to be_falsey }
  end

  describe '.messages_not_allotted?' do
    subject { described_class.messages_not_allotted?(user) }
    it { is_expected.to be_truthy }
  end

  describe 'send_report_limited?' do
    subject { described_class.send_report_limited?(user.uid) }
    before { RedisClient.new.flushall }
    it { is_expected.to be_falsey }
  end
end
