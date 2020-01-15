require 'rails_helper'

RSpec.describe DeleteFromS3Worker do
  describe '#perform' do
    context 'params["klass"] is a child class of S3::Tweet' do
      it do
        [S3::FavoriteTweet, S3::MentionTweet, S3::StatusTweet].each.with_index do |klass, i|
          expect(klass).to receive(:delete).with(uid: i)
          described_class.new.perform('klass' => klass.to_s, 'key' => i)
        end
      end
    end

    context 'params["klass"] is NOT a child class of S3::Tweet' do
      it do
        [S3::Followership, S3::Friendship, S3::Profile].each.with_index do |klass, i|
          bucket = "bucket#{i}"
          expect(klass.client).to receive(:delete_object).with(bucket: bucket, key: i)
          described_class.new.perform('klass' => klass.to_s, 'bucket' => bucket, 'key' => i)
        end
      end
    end
  end
end
