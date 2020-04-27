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

    it do
      expect(welcome_message).to receive(:send_starting_message!)
      expect(welcome_message).to receive(:send_success_message!).and_return('dm')
      expect(welcome_message).not_to receive(:send_failed_message!)
      expect { subject }.to change { CreateWelcomeMessageLog.all.size }.by(1)
      expect(subject).to eq('dm')
    end

    context '#send_starting_message! raises an exception' do
      let(:exception) { WelcomeMessage::StartingFailed.new("#{RuntimeError} failed") }
      before { allow(welcome_message).to receive(:send_starting_message!).and_raise('failed') }
      it do
        expect { subject }.to raise_error(exception.class, exception.message)
        expect(welcome_message.log).to satisfy do |log|
          log.error_class == exception.class.to_s && log.error_message == exception.message
        end
      end
    end
  end

  describe '#create_dm' do
    let(:instance) { described_class.new(user: user, token: 'token') }
    let(:sender) { user }
    let(:recipient) { double('recipient', uid: 1) }
    let(:dm) { double('dm', id: 11, truncated_message: 'text') }
    subject { instance.send(:create_dm, sender, recipient, 'text') }

    it do
      expect(sender).to receive_message_chain(:api_client, :create_direct_message_event).with(no_args).with(1, 'text').and_return(dm)
      expect(instance).to receive(:update!).with(message_id: dm.id, message: 'text')
      expect(subject).to eq(dm)
    end
  end

  describe '#send_starting_message!' do
    let(:instance) { described_class.new(user: user, token: 'token') }
    subject { instance.send(:send_starting_message!) }

    before { allow(User).to receive(:egotter).and_return('egotter_user') }

    it do
      expect(described_class::StartingMessageBuilder).to receive_message_chain(:new, :build).with(user, 'token').with(no_args).and_return('text')
      expect(instance).to receive(:create_dm).with(user, 'egotter_user', 'text')
      subject
    end
  end

  describe '#send_success_message!' do
    let(:instance) { described_class.new(user: user, token: 'token') }
    subject { instance.send(:send_success_message!) }

    it do
      expect(described_class::SuccessMessageBuilder).to receive_message_chain(:new, :build).with(user, 'token').with(no_args).and_return('text')
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(no_args).with(no_args).with(event: anything)
      subject
    end
  end

  describe '#send_failed_message!' do
    let(:instance) { described_class.new(user: user, token: 'token') }
    subject { instance.send(:send_failed_message!) }

    before { allow(User).to receive(:egotter).and_return('egotter_user') }

    it do
      expect(described_class::FailedMessageBuilder).to receive_message_chain(:new, :build).with(user, 'token').with(no_args).and_return('text')
      expect(instance).to receive(:create_dm).with(user, 'egotter_user', 'text')
      subject
    end
  end
end
