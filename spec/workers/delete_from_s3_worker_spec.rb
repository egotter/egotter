require 'rails_helper'

RSpec.describe DeleteFromS3Worker do
  describe '#perform' do
    it do
      [
          S3::Followership,
          S3::Friendship,
          S3::Profile,
          S3::FavoriteTweet,
          S3::MentionTweet,
          S3::StatusTweet,
      ].each.with_index do |klass, i|
        bucket = "bucket#{i}"
        expect(klass.client).to receive(:delete_object).with(bucket: bucket, key: i)
        described_class.new.perform('klass' => klass.to_s, 'bucket' => bucket, 'key' => i)
      end
    end
  end
end
