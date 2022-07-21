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

  describe '#exception' do
    let(:error) { RuntimeError.new }
    subject { instance.exception(error) }
    it do
      expect(instance).to receive(:log).with(Logger::ERROR, instance_of(String), {backtrace: error.backtrace})
      subject
    end
  end

  describe '#log' do
    let(:logger) { instance_double(Logger, 'log/test.log', level: Logger::INFO) }
    let(:level) { Logger::WARN }
    let(:message) { 'msg' }
    let(:context) { {x: 1} }
    let(:formatted_message) { "warn: #{message}" }
    let(:callback_result) { [] }
    subject { instance.log(level, message, {a: 1}) }

    before do
      described_class.broadcast { callback_result << true }
      allow(instance).to receive(:logger).and_return(logger)
      allow(instance).to receive(:current_context).and_return(context)
      allow(instance).to receive(:format_message).with(Logger::WARN, message, context).and_return(formatted_message)
    end

    it do
      expect(logger).to receive(:add).with(level, formatted_message)
      expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', message, {a: 1, x: 1}, kind_of(Time))
      subject
      expect(callback_result[0]).to be_truthy
    end

    context 'too long message is passed' do
      let(:message) { 'a' * 70000 }
      it do
        expect(logger).to receive(:add).with(level, formatted_message)
        expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', "#{message.slice(0, 49997)}...", {a: 1, x: 1}, kind_of(Time))
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
