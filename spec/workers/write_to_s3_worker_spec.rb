require 'rails_helper'

RSpec.describe WriteToS3Worker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:klass) { 'S3::Followership' }
    let(:params) { {'klass' => 'S3::Followership', 'bucket' => 'bucket', 'key' => 'key', 'body' => 'body'} }
    subject { worker.perform(params) }
    it do
      expect(worker).to receive(:do_perform).with(S3::Followership, 'bucket', 'key', 'body')
      subject
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(worker).to receive(:do_perform).with(any_args).and_raise(error) }
      it do
        expect(described_class).to receive(:perform_in).with(2, params, 'retry_count' => 1)
        subject
      end
    end
  end

  describe '#do_perform' do
    subject { worker.send(:do_perform, klass, bucket, key, body) }

    [
        S3::Followership,
        S3::Friendship,
        S3::Profile,
    ].each.with_index do |target, i|
      context "klass is #{target}" do
        let(:klass) { target }
        let(:bucket) { "bucket-#{target}" }
        let(:key) { "key-#{target}" }
        let(:body) { "body-#{target}" }

        it do
          expect(klass.client).to receive(:put_object).with(bucket: bucket, key: key, body: body)
          subject
        end
      end
    end

    [
        S3::FavoriteTweet,
        S3::MentionTweet,
        S3::StatusTweet,
    ].each.with_index do |target, i|
      context "klass is #{target}" do
        let(:klass) { target }
        let(:bucket) { "bucket-#{target}" }
        let(:key) { "key-#{target}" }
        let(:body) { "body-#{target}" }

        it do
          expect(klass.client.instance_variable_get(:@s3)).to receive(:put_object).with(bucket: bucket, key: key, body: body)
          subject
        end
      end
    end
  end
end
