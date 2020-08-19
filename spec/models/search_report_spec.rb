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

  describe '#send_starting_message_from_user?' do
    subject { report.send(:send_starting_message_from_user?) }
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
