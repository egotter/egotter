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
    let(:level) { 'level' }
    let(:message) { 'abc' }
    subject { described_class.log(level, message) }
    it do
      expect(Rails.logger).to receive(:add).with(level) do |*args, &blk|
        expect(blk.call).to eq("[Airbag] #{message}")
      end
      subject
    end
  end
end
