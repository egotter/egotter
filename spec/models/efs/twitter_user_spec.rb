require 'rails_helper'

RSpec.describe Efs::TwitterUser do
  let(:twitter_user) { create(:twitter_user) }

  before do
    allow(S3::Profile).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(user_info: '{"dummy": true}')
    allow(S3::Friendship).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(S3::Friendship.new(friend_uids: 'friend_uids'))
    allow(S3::Followership).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(S3::Followership.new(follower_uids: 'follower_uids'))
  end

  describe '.import_from!' do
    subject { described_class.import_from!(twitter_user.id, twitter_user.uid, twitter_user.screen_name, '{"dummy": true}', 'friend_uids', 'follower_uids') }

    it do
      subject
      expect(described_class.find_by(twitter_user.id)).to satisfy do |result|
        result.uid == twitter_user.uid &&
            result.screen_name == twitter_user.screen_name &&
            result.profile == {dummy: true} &&
            result.friend_uids == 'friend_uids' &&
            result.follower_uids == 'follower_uids'
      end
    end
  end
end
