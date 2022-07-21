require 'rails_helper'

RSpec.describe Airbag, type: :model do
  describe '.debug' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { described_class.debug(message, &block) }
    it do
      expect(described_class).to receive(:log).with(Logger::DEBUG, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '.info' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { described_class.info(message, &block) }
    it do
      expect(described_class).to receive(:log).with(Logger::INFO, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '.warn' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { described_class.warn(message, &block) }
    it do
      expect(described_class).to receive(:log).with(Logger::WARN, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '.error' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { described_class.error(message, &block) }
    it do
      expect(described_class).to receive(:log).with(Logger::ERROR, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '.log' do
    let(:logger) { instance_double(Logger, 'log/test.log') }
    let(:level) { Logger::WARN }
    let(:message) { 'msg' }
    let(:formatted_message) { "warn: #{message}" }
    subject { described_class.log(level, message, {}) }

    before do
      Airbag.broadcast(target: :slack, channel: :airbag, tag: 'test', level: Logger::INFO)
      allow(described_class).to receive(:logger).and_return(logger)
      allow(described_class).to receive(:format_message).with(Logger::WARN, message).and_return(formatted_message)
    end

    it do
      expect(logger).to receive(:add).with(level, formatted_message)
      expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', formatted_message, {}, kind_of(Time))
      expect(SendMessageToSlackWorker).to receive(:perform_async).with(:airbag, formatted_message)
      subject
    end

    context 'too long message is passed' do
      let(:message) { 'a' * 70000 }
      it do
        expect(logger).to receive(:add).with(level, formatted_message)
        expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', "#{formatted_message.slice(0, 49997)}...", {}, kind_of(Time))
        expect(SendMessageToSlackWorker).to receive(:perform_async).with(:airbag, "#{formatted_message.slice(0, 997)}...")
        subject
      end
    end
  end
end
