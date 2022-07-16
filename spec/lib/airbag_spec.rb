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
    subject { described_class.log(level, message, {}) }
    before { allow(described_class).to receive(:logger).and_return(logger) }
    it do
      expect(logger).to receive(:add).with(level, instance_of(String))
      expect(CreateAirbagLogWorker).to receive(:perform_async).with('WARN', instance_of(String), {}, kind_of(Time))
      subject
    end
  end
end
