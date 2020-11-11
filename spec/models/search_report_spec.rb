require 'rails_helper'

RSpec.describe SearchReport, type: :model do
  let(:user) { create(:user) }
  let(:report) { described_class.new }

  describe '.generate_token' do
    subject { described_class.generate_token }
    it 'generates a unique token' do
      is_expected.to be_truthy
    end
  end

  describe '#deliver!' do
    let(:dm) { double('dm', id: 1, truncated_message: 'tm') }
    let(:report) { described_class.new(user: user, token: 'token') }
    subject { report.deliver! }
    it do
      expect(report).to receive(:send_start_message)
      expect(report).to receive(:send_message).and_return(dm)
      expect(report).to receive(:update!).with(message_id: dm.id, message: dm.truncated_message)
      subject
    end
  end

  describe '#send_start_message' do
    let(:report) { described_class.new(user: user) }
    subject { report.send(:send_start_message) }
    before do
      allow(report).to receive(:start_message).and_return('message')
    end
    it do
      expect(user).to receive_message_chain(:api_client, :create_direct_message_event).with(User::EGOTTER_UID, 'message')
      subject
    end
  end

  describe '#send_message' do
    let(:report) { described_class.new(user: user) }
    subject { report.send(:send_message) }
    before do
      allow(report).to receive(:report_message).and_return('message')
      allow(described_class).to receive(:build_direct_message_event).with(user.uid, 'message').and_return('event')
    end
    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(event: 'event')
      subject
    end
  end

  describe '#messages_not_allotted?' do
    subject { report.send(:messages_not_allotted?) }
    before { allow(report).to receive(:user).and_return(user) }
    it do
      expect(PeriodicReport).to receive(:messages_allotted?).with(user).and_return(true)
      expect(PeriodicReport).to receive(:allotted_messages_left?).with(user).and_return(true)
      is_expected.to be_falsey
    end
  end

  describe '.build_direct_message_event' do
    subject { described_class.build_direct_message_event(1, 'message') }
    it do
      event = subject
      expect(event[:message_create][:target][:recipient_id]).to eq(1)
      expect(event[:message_create][:message_data][:text]).to eq('message')
      expect(event[:message_create][:message_data][:quick_reply][:options][0][:label]).not_to include('missing')
    end
  end
end
