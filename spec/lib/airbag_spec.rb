require 'rails_helper'

RSpec.describe Airbag, type: :model do
  describe '.info' do
    let(:message) { 'abc' }
    let(:block) { Proc.new {} }
    subject { described_class.info(message, &block) }
    it do
      expect(described_class).to receive(:log).with(Logger::INFO, message) do |*args, &blk|
        expect(blk).to eq(block)
      end
      subject
    end
  end

  describe '.log' do
    let(:logger) { double('logger') }
    let(:level) { 'level' }
    let(:message) { 'abc' }
    subject { described_class.log(level, message) }
    before { allow(described_class).to receive(:logger).and_return(logger) }
    it do
      expect(logger).to receive(:add).with(level, message)
      subject
    end
  end
end
