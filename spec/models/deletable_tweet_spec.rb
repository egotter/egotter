require 'rails_helper'

RSpec.describe DeletableTweet, type: :model do
  let(:user) { create(:user) }
  let(:record) { create(:deletable_tweet, uid: user.uid) }

  describe '#delete_tweet!' do
    subject { record.delete_tweet! }
    it do
      expect(record).to receive(:destroy_status!)
      subject
    end
  end

  describe '.reserve_deletion' do
    let(:tweet_ids) { [record.tweet_id] }
    subject { described_class.reserve_deletion(user, tweet_ids) }
    it do
      subject
      expect(record.reload.deletion_reserved_at).to be_truthy
    end
  end
end
