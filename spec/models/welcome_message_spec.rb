require 'rails_helper'

RSpec.describe WelcomeMessage, type: :model do
  let(:user) { create(:user, with_settings: true) }

  describe '.welcome' do
    it do
      expect(described_class).to receive(:new).with(user_id: user.id, token: /\w+/)
      described_class.welcome(user.id)
    end
  end

  describe '#deliver!' do
    let(:welcome_message) { build(:welcome_message, user: user) }

    subject { welcome_message.deliver! }

    let(:dm1) { instance_double(DirectMessage, id: 'id1', truncated_message: 'tm1') }
    let(:dm2) { instance_double(DirectMessage, id: 'id2', truncated_message: 'tm2') }
    let(:dm3) { instance_double(DirectMessage, id: 'id3', truncated_message: 'tm3') }

    it do
      expect(welcome_message).to receive(:send_starting_message!).and_return(dm1)
      expect(welcome_message).to receive(:update!).with(message_id: dm1.id, message: dm1.truncated_message).and_call_original

      expect(welcome_message).to receive(:send_initialization_success_message!).and_return(dm3)
      expect(welcome_message).to receive(:update!).with(message_id: dm3.id, message: dm3.truncated_message).and_call_original

      expect(welcome_message).not_to receive(:send_initialization_failed_message!)

      expect { subject }.to change { CreateWelcomeMessageLog.all.size }.by(1)

      expect(welcome_message.message_id).to eq('id3')
      expect(welcome_message.message).to eq('tm3')
    end

    context '#send_starting_message! raises an exception' do
      let(:exception) { WelcomeMessage::StartingFailed.new("#{RuntimeError} failed") }
      before { allow(welcome_message).to receive(:send_starting_message!).and_raise('failed') }
      it do
        expect(welcome_message).not_to receive(:update!)
        expect { subject }.to raise_error(exception.class, exception.message)
        expect(welcome_message.log).to satisfy do |log|
          log.error_class == exception.class.to_s && log.error_message == exception.message
        end
      end
    end
  end
end
