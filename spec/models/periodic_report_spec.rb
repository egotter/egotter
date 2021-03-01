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

    context 'periodic_report_id is not passed' do
      before do
        allow(described_class).to receive(:generate_token).and_return('token')
        allow(described_class).to receive(:new).with(user: user, token: 'token').and_call_original
        allow(described_class).to receive(:build_report_message).with(user, 'token', options).and_return('message')
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

  describe '.remind_access_message' do
    subject { described_class.remind_access_message }
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

  describe '.cannot_send_messages_message' do
    subject { described_class.cannot_send_messages_message }
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
    subject { described_class.not_following_message }
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

  describe '#send_direct_message' do
    let(:user) { create(:user) }
    let(:report) { described_class.new(user: user, message: 'message', quick_reply_buttons: 'buttons') }
    subject { report.send_direct_message }

    it do
      expect(report).to receive(:append_remind_message_if_needed).and_return(report.message)
      expect(report).to receive(:send_start_message)
      expect(described_class).to receive(:build_direct_message_event).with(user.uid, 'message', quick_reply_buttons: 'buttons').and_return('event')
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(event: 'event').and_return('dm')
      is_expected.to eq('dm')
    end
  end

  describe '#send_remind_reply_message?' do
    let(:report) { described_class.new }
    subject { report.send_remind_reply_message? }

    before { allow(report).to receive(:user).and_return(user) }

    context 'dont_send_remind_message is set' do
      before { report.dont_send_remind_message = true }
      it { is_expected.to be_falsey }
    end

    context 'messages_allotted? returns true' do
      before { allow(described_class).to receive(:messages_allotted?).with(user).and_return(true) }
      it do
        expect(described_class).to receive(:allotted_messages_will_expire_soon?).with(user).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'messages_allotted? returns false' do
      before { allow(described_class).to receive(:messages_allotted?).with(user).and_return(false) }
      it { is_expected.to be_truthy }
    end
  end

  describe '#send_remind_access_message?' do
    let(:report) { described_class.new }
    subject { report.send_remind_access_message? }

    before { allow(report).to receive(:user).and_return(user) }

    context 'dont_send_remind_message is set' do
      before { report.dont_send_remind_message = true }
      it { is_expected.to be_falsey }
    end

    context 'messages_allotted? returns true' do
      before { allow(described_class).to receive(:messages_allotted?).with(user).and_return(true) }
      it do
        expect(described_class).to receive(:web_access_soft_limited?).with(user).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'messages_allotted? returns false' do
      before { allow(described_class).to receive(:messages_allotted?).with(user).and_return(false) }
      it { is_expected.to be_truthy }
    end
  end

  describe '#send_remind_reply_message' do
    let(:report) { described_class.new }
    subject { report.send_remind_reply_message }

    before { allow(report).to receive(:user).and_return(user) }

    it do
      expect(described_class).to receive(:remind_reply_message).and_call_original
      expect(report).to receive(:send_remind_message).with(instance_of(String))
      subject
    end
  end

  describe '#send_remind_access_message' do
    let(:report) { described_class.new }
    subject { report.send_remind_access_message }

    before { allow(report).to receive(:user).and_return(user) }

    it do
      expect(described_class).to receive(:remind_access_message).and_call_original
      expect(report).to receive(:send_remind_message).with(instance_of(String))
      subject
    end
  end

  describe '#send_remind_message' do
    let(:report) { described_class.new }
    subject { report.send_remind_message('message') }

    before { allow(report).to receive(:user).and_return(user) }

    it do
      expect(described_class).to receive(:build_direct_message_event).with(user.uid, 'message').and_return('event')
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(no_args).with(event: 'event')
      subject
    end
  end

  describe '.default_quick_reply_options' do
    subject { described_class.default_quick_reply_options }
    it do
      subject.each do |options|
        expect(options[:label]).not_to include('missing')
        expect(options[:description]).not_to include('missing')
      end
    end
  end

  describe '.unsubscribe_quick_reply_options' do
    subject { described_class.unsubscribe_quick_reply_options }
    it do
      subject.each do |options|
        expect(options[:label]).not_to include('missing')
        expect(options[:description]).not_to include('missing')
      end
    end
  end

  describe '.build_direct_message_event' do
    subject { described_class.build_direct_message_event(1, 'message') }
    before { allow(described_class).to receive(:default_quick_reply_options).and_return('options') }
    it do
      event = subject
      expect(event[:message_create][:target][:recipient_id]).to eq(1)
      expect(event[:message_create][:message_data][:text]).to eq('message')
      expect(event[:message_create][:message_data][:quick_reply][:options]).to eq('options')
    end
  end

  describe '.allotted_messages_will_expire_soon?' do
    subject { described_class.allotted_messages_will_expire_soon?(user) }

    before do
      allow(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :remaining).with(user.uid).and_return(ttl)
    end

    context 'remaining ttl is short' do
      let(:ttl) { 1.hour }
      it { is_expected.to be_truthy }
    end

    context 'remaining ttl is long' do
      let(:ttl) { 6.hours }
      it { is_expected.to be_falsey }
    end
  end

  describe '.allotted_messages_left?' do
    subject { described_class.allotted_messages_left?(user) }

    context 'Sending DMs count is less than or equal to 4' do
      before { allow(GlobalSendDirectMessageCountByUser).to receive_message_chain(:new, :count).with(user.uid).and_return(4) }
      it { is_expected.to be_truthy }
    end

    context 'Sending DMs count is greater than 3' do
      before { allow(GlobalSendDirectMessageCountByUser).to receive_message_chain(:new, :count).with(user.uid).and_return(5) }
      it { is_expected.to be_falsey }
    end
  end

  describe '.messages_allotted?' do
    subject { described_class.messages_allotted?(user) }
    it do
      expect(GlobalDirectMessageReceivedFlag).to receive_message_chain(:new, :received?).with(user.uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '.web_access_soft_limited?' do
    subject { described_class.web_access_soft_limited?(user) }

    context 'last access is 1 day ago' do
      before { AccessDay.create!(user_id: user.id, date: 1.day.ago.to_date) }
      it { is_expected.to be_falsey }
    end

    context 'last access is 6 days ago' do
      before { AccessDay.create!(user_id: user.id, date: 6.days.ago.to_date) }
      it { is_expected.to be_truthy }
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
    it { is_expected.to be_falsey }
  end
end
