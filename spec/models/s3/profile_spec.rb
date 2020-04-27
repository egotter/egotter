require 'rails_helper'

RSpec.describe S3::Profile do
  let(:twitter_user_id) { 1 }

  describe '.find_by' do
    subject { described_class.find_by(twitter_user_id: twitter_user_id) }
    it do
      expect(described_class).to receive(:find_by_current_scope).with(described_class.payload_key, :twitter_user_id, twitter_user_id)
      subject
    end
  end

  describe '.delete_by' do
    subject { described_class.delete_by(twitter_user_id: twitter_user_id) }
    it do
      expect(described_class).to receive(:delete).with(twitter_user_id).and_call_original
      expect(DeleteFromS3Worker).to receive(:perform_async).with(klass: described_class, bucket: described_class.bucket_name, key: twitter_user_id)
      subject
    end
  end

  describe '.import_from!' do
    # TODO
  end
end
