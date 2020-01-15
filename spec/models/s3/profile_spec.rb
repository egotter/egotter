require 'rails_helper'

RSpec.describe S3::Profile do
  describe '.delete_by' do
    it do
      expect(DeleteFromS3Worker).to receive(:perform_async).with(klass: described_class, bucket: described_class.bucket_name, key: '1')
      described_class.delete_by(twitter_user_id: 1)
    end
  end
end
