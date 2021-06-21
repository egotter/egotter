require 'rails_helper'

RSpec.describe FriendsCountPoint, type: :model do
  describe '.create_by_twitter_user' do
    let(:twitter_user) { create(:twitter_user) }
    subject { described_class.create_by_twitter_user(twitter_user) }
    before { allow(twitter_user).to receive(:friends_count).and_return(100) }
    it { expect { subject }.to change { described_class.all.size }.by(1) }
  end
end
