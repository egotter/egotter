require 'rails_helper'

RSpec.describe Airbag, type: :model do
  let(:instance) { described_class.instance }

  [
      [:debug, Logger::DEBUG],
      [:info, Logger::INFO],
      [:warn, Logger::WARN],
      [:error, Logger::ERROR],
  ].each do |method, level|
    describe "##{method}" do
      let(:message) { 'msg' }
      subject { instance.send(method, message, id: 1) }
      it do
        expect(instance).to receive(:log).with(level, message, {id: 1})
        subject
      end

      context 'block is passed' do
        let(:block) { Proc.new { 'blk' } }
        subject { instance.send(method, &block) }
        it do
          expect(instance).to receive(:log).with(level, 'blk', {})
          subject
        end
      end
    end
  end

  describe '#exception' do
    let(:errors) { [] }
    subject { instance.exception(errors[0]) }
    before do
      begin
        raise 'aaa'
      rescue
        begin
          raise 'bbb'
        rescue => e
          errors << e
        end
      end
    end
    it do
      expect(instance).to receive(:log).with(Logger::ERROR, instance_of(String), {backtrace: errors[0].backtrace, cause_backtrace: errors[0].cause.backtrace})
      subject
    end
  end

  describe '#log' do
    let(:logger) { instance_double(Logger, 'log/test.log', level: Logger::INFO) }
    let(:level) { Logger::WARN }
    let(:message) { 'msg' }
    let(:props) { {a: 1} }
    let(:context) { {x: 1} }
    let(:formatted_message) { "warn: #{message}" }
    let(:callback_result) { [] }
    subject { instance.log(level, message, props) }

    before do
      described_class.broadcast { callback_result << true }
      allow(instance).to receive(:logger).and_return(logger)
      allow(instance).to receive(:current_context).and_return(context)
      allow(instance).to receive(:format_message).with(Logger::WARN, message, props, context).and_return(formatted_message)
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
