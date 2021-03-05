require 'rails_helper'

RSpec.describe WelcomeMessage, type: :model do
  let(:user) { create(:user) }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
    allow(described_class).to receive(:generate_token).and_return('token')
  end

  describe '.welcome' do
    subject { described_class.welcome(user.id) }
    before do
      allow(described_class::WelcomeMessageBuilder).to receive_message_chain(:new, :build).
          with(user, 'token').with(no_args).and_return('message')
    end
    it do
      expect(described_class).to receive(:new).with(user_id: user.id, token: 'token', message: 'message')
      subject
    end
  end

  describe '.help_message' do
    subject { described_class.help_message(user) }
    it { is_expected.to be_truthy }
  end

  describe '#set_prefix_message' do
    let(:instance) { described_class.new }
    subject { instance.set_prefix_message('text') }
    it do
      subject
      expect(instance.instance_variable_get(:@prefix_message)).to eq('text')
    end
  end

  describe '#deliver!' do
    let(:instance) { described_class.new(user: user, token: 'token') }
    subject { instance.deliver! }
    before { allow(instance).to receive(:send_message!).and_return(double('dm', id: 1)) }

    it do
      expect(instance).to receive(:send_starting_message!)
      expect(instance).to receive(:send_message!)
      subject
    end
  end

  describe '#send_starting_message!' do
    let(:instance) { described_class.new(user: user, token: 'token') }
    subject { instance.send(:send_starting_message!) }

    before do
      allow(described_class::StartingMessageBuilder).to receive_message_chain(:new, :build).
          with(user, 'token').with(no_args).and_return('message')
    end

    it do
      expect(user).to receive_message_chain(:api_client, :create_direct_message_event).with(User::EGOTTER_UID, 'message')
      subject
    end
  end

  describe '#send_message!' do
    let(:instance) { described_class.new(user: user, token: 'token', message: 'message') }
    subject { instance.send(:send_message!) }

    before do
      allow(described_class).to receive(:build_direct_message_event).with(user.uid, 'message').and_return('event')
    end

    it do
      expect(User).to receive_message_chain(:egotter, :api_client, :create_direct_message_event).with(event: 'event')
      subject
    end
  end

  describe '.build_direct_message_event' do
    subject { described_class.build_direct_message_event(1, 'text') }
    it { is_expected.to be_truthy }
  end
end

RSpec.describe WelcomeMessage::StartingMessageBuilder, type: :model do
  let(:user) { create(:user) }
  let(:instance) { described_class.new(user, 'token') }

  describe '#build' do
    subject { instance.build }
    it { is_expected.to be_truthy }
  end
end

RSpec.describe WelcomeMessage::WelcomeMessageBuilder, type: :model do
  let(:user) { create(:user, with_settings: true) }
  let(:instance) { described_class.new(user, 'token') }

  describe '#build' do
    subject { instance.build }
    it { is_expected.to be_truthy }
  end
end
