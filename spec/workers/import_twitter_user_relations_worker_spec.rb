require 'rails_helper'

RSpec.describe ImportTwitterUserRelationsWorker do
  let(:twitter_user) { create(:twitter_user) }
  let(:instance) { described_class.new }
  let(:client) { ApiClient.instance }

  describe '#import_other_relationships' do
    subject { instance.import_other_relationships(twitter_user) }

    it 'calls Xxx.import_by!' do
      [
          Unfriendship,
          Unfollowership,
          OneSidedFriendship,
          OneSidedFollowership,
          MutualFriendship,
          BlockFriendship,
          InactiveFriendship,
          InactiveFollowership,
          InactiveMutualFriendship
      ].each do |klass|
        expect(klass).to receive(:import_by!).with(twitter_user: twitter_user)
      end
      subject
    end
  end
end
