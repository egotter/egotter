require 'rails_helper'

RSpec.describe S3::Client do
  let(:s3) { double('s3') }
  let(:instance) { described_class.new('bucket', 'klass') }
  let(:key) { 1 }

  before do
    instance.instance_variable_set(:@s3, s3)
  end

  describe '#read' do
    subject { instance.read(key) }

    it do
      expect(s3).to receive_message_chain(:get_object, :body, :read).
          with(bucket: 'bucket', key: key.to_s).with(no_args).with(no_args).and_return('output')
      is_expected.to eq('output')
    end
  end

  describe '#write' do
    subject { instance.write(key, 'input') }

    it do
      expect(WriteToS3Worker).to receive(:perform_async).with(klass: 'klass', bucket: 'bucket', key: key, body: 'input')
      subject
    end
  end

  describe '#delete' do
    subject { instance.delete(key) }

    it do
      expect(DeleteFromS3Worker).to receive(:perform_async).with(klass: 'klass', bucket: 'bucket', key: key)
      subject
    end
  end
end
