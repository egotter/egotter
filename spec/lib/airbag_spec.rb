require 'rails_helper'

RSpec.describe Airbag, type: :model do
  let(:instance) { described_class.instance }

  describe '#debug' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { instance.debug(message, &block) }
    it do
      expect(instance).to receive(:log).with(Logger::DEBUG, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '#info' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { instance.info(message, &block) }
    it do
      expect(instance).to receive(:log).with(Logger::INFO, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '#warn' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { instance.warn(message, &block) }
    it do
      expect(instance).to receive(:log).with(Logger::WARN, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '#error' do
    let(:message) { 'msg' }
    let(:block) { Proc.new {} }
    subject { instance.error(message, &block) }
    it do
      expect(instance).to receive(:log).with(Logger::ERROR, message, {}) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '#log' do
    let(:logger) { instance_double(Logger, 'log/test.log', level: Logger::INFO) }
    let(:level) { Logger::WARN }
    let(:message) { 'msg' }
    let(:formatted_message) { "warn: #{message}" }
    let(:callback_result) { [] }
    subject { instance.log(level, message, {}) }

    before do
      Airbag.broadcast { callback_result << true }
      allow(instance).to receive(:logger).and_return(logger)
      allow(instance).to receive(:format_message).with(Logger::WARN, message).and_return(formatted_message)
    end

    it do
      expect(logger).to receive(:add).with(level, formatted_message)
      expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', formatted_message, {}, kind_of(Time))
      subject
      expect(callback_result[0]).to be_truthy
    end

    context 'too long message is passed' do
      let(:message) { 'a' * 70000 }
      it do
        expect(logger).to receive(:add).with(level, formatted_message)
        expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', "#{formatted_message.slice(0, 49997)}...", {}, kind_of(Time))
        subject
        expect(callback_result[0]).to be_truthy
      end
    end
  end

  [:debug, :info, :warn, :error, :benchmark, :broadcast, :disable!].each do |method_name|
    describe ".#{method_name}" do
      subject { described_class.send(method_name) }
      it do
        expect(instance).to receive(method_name)
        subject
      end
    end
  end
end
