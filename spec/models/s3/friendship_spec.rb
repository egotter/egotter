require 'rails_helper'

RSpec.describe S3::Friendship do
  let(:client) { described_class.client }

  describe '.store' do
    it do
      expect(client).to_not receive(:put_object)
      described_class.store(1, 'body')
    end
  end

  describe '.fetch' do
    it do
      expect(client).to_not receive(:get_object)
      described_class.fetch(1)
    end
  end

  describe '.delete_by' do
    it do
      expect(DeleteFromS3Worker).to receive(:perform_async).with(klass: described_class, bucket: described_class.bucket_name, key: '1')
      described_class.delete_by(twitter_user_id: 1)
    end
  end
end
