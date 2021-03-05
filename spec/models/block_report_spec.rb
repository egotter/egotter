require 'rails_helper'

RSpec.describe BlockReport, type: :model do
  let(:user) { create(:user) }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#you_are_blocked' do
    subject { described_class.you_are_blocked(user.id) }
    it { is_expected.to be_truthy }
  end

  describe '#not_following_message' do
    subject { described_class.not_following_message(user) }
    before { allow(described_class).to receive(:fetch_blocked_users).and_return([create(:twitter_db_user)]) }
    it { is_expected.to be_truthy }
  end

  describe '#access_interval_too_long_message' do
    subject { described_class.access_interval_too_long_message(user) }
    before { allow(described_class).to receive(:fetch_blocked_users).and_return([create(:twitter_db_user)]) }
    it { is_expected.to be_truthy }
  end

  describe '#request_interval_too_short_message' do
    subject { described_class.request_interval_too_short_message(user) }
    before { allow(described_class).to receive(:fetch_blocked_users).and_return([create(:twitter_db_user)]) }
    it { is_expected.to be_truthy }
  end

  describe '#report_stopped_message' do
    subject { described_class.report_stopped_message(user) }
    before { allow(described_class).to receive(:fetch_blocked_users).and_return([create(:twitter_db_user)]) }
    it { is_expected.to be_truthy }
  end

  describe '#report_restarted_message' do
    subject { described_class.report_restarted_message(user) }
    before { allow(described_class).to receive(:fetch_blocked_users).and_return([create(:twitter_db_user)]) }
    it { is_expected.to be_truthy }
  end

  describe '#report_message' do
    subject { described_class.report_message(user, 'token') }
    it { is_expected.to be_truthy }
  end

  describe '#deliver!' do
    let(:dm) { double('dm', id: 1, truncated_message: 'tm') }
    let(:report) { described_class.new(user: user, token: 'token') }
    subject { report.deliver! }
    it do
      expect(described_class).to receive(:send_start_message).with(user)
      expect(report).to receive(:send_message).and_return(dm)
      expect(report).to receive(:update!).with(message_id: dm.id, message: dm.truncated_message)
      subject
    end
  end

  describe '.send_start_message' do
    subject { described_class.send_start_message(user) }
    before { allow(described_class).to receive(:start_message).with(user).and_return('message') }
    it do
      expect(user).to receive_message_chain(:api_client, :create_direct_message_event).with(User::EGOTTER_UID, 'message')
      subject
    end
  end

  describe '#send_message' do
    subject { described_class.new(user: user, token: 'token').send(:send_message) }
    before do
      allow(described_class).to receive(:report_message).with(user, 'token').and_return('message')
      allow(described_class).to receive(:build_direct_message_event).with(user.uid, 'message').and_return('event')
    end
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(event: 'event')
      subject
    end
  end

  describe '#fetch_blocked_users' do
    subject { described_class.fetch_blocked_users(user) }
    before do
      BlockingRelationship.create!(from_uid: 1, to_uid: user.uid)
      create(:twitter_db_user, uid: 1)
    end
    it { is_expected.to be_truthy }
  end

  describe '.mask_name' do
    subject { described_class.mask_name(name) }

    context 'name is blank' do
      let(:name) { nil }
      it { is_expected.to eq('') }
    end

    context 'name.length is 1' do
      let(:name) { 'a' }
      it { is_expected.to eq('*') }
    end

    context 'name.length is 2' do
      let(:name) { 'ab' }
      it { is_expected.to eq('a*') }
    end

    context 'name.length is 5' do
      let(:name) { 'abcde' }
      it { is_expected.to eq('ab***') }
    end

    context 'has_subscription is true' do
      let(:name) { 'abcde' }
      subject { described_class.mask_name(name, true) }
      it { is_expected.to eq('abcde') }
    end
  end
end
