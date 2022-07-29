require 'rails_helper'

RSpec.describe DeletableTweet, type: :model do
  let(:user) { create(:user) }
  let(:record) { create(:deletable_tweet, uid: user.uid, tweet_id: 1) }

  describe '#delete_tweet!' do
    subject { record.delete_tweet! }
    it do
      expect(record).to receive_message_chain(:user, :api_client, :twitter, :destroy_status).with(1)
      expect(record).to receive(:update).with(deleted_at: instance_of(ActiveSupport::TimeWithZone))
      subject
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(record).to receive(:user).and_raise(error) }
      it do
        expect(record).not_to receive(:update).with(deleted_at: anything)
        expect(record).to receive(:update).with(deletion_reserved_at: nil)
        expect { subject }.to raise_error(error)
      end
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
