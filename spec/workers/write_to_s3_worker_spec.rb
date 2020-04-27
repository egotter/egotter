require 'rails_helper'

RSpec.describe WriteToS3Worker do
  describe '#perform' do
    [
        S3::Followership,
        S3::Friendship,
        S3::Profile,
    ].each.with_index do |klass, i|
      context klass.to_s do
        it do
          bucket = "bucket#{i}"
          key = "key#{i}"
          body = "body#{i}"

          expect(klass.client).to receive(:put_object).with(bucket: bucket, key: key, body: body)
          described_class.new.perform('klass' => klass.to_s, 'bucket' => bucket, 'key' => key, 'body' => body)
        end
      end
    end

    [
        S3::FavoriteTweet,
        S3::MentionTweet,
        S3::StatusTweet,
    ].each.with_index do |klass, i|
      context klass.to_s do
        it do
          bucket = "bucket#{i}"
          key = "key#{i}"
          body = "body#{i}"

          expect(klass.client.instance_variable_get(:@s3)).to receive(:put_object).with(bucket: bucket, key: key, body: body)
          described_class.new.perform('klass' => klass.to_s, 'bucket' => bucket, 'key' => key, 'body' => body)
        end
      end
    end
  end
end
