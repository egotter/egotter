require 'rails_helper'

RSpec.describe FollowersCountPoint, type: :model do
  describe '.create_by_twitter_user' do
    let(:twitter_user) { create(:twitter_user) }
    subject { described_class.create_by_twitter_user(twitter_user) }
    before { allow(twitter_user).to receive(:followers_count).and_return(100) }
    it { expect { subject }.to change { described_class.all.size }.by(1) }
  end

  describe '.import_by_uid' do
    let(:uid) { 1 }
    subject { described_class.import_by_uid(uid, limit: 2) }
    before do
      3.times { |n| build(:twitter_user, uid: uid, created_at: Time.zone.now + (n * 10).minutes).save(validate: false) }
    end
    it do
      expect(described_class).to receive(:create_by_twitter_user).with(anything).twice
      subject
    end
    it { expect { subject }.to change { described_class.all.size }.by(2) }
  end
end
