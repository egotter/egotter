require 'rails_helper'

RSpec.describe TwitterUserFetcher do
  let(:twitter_user) { build(:twitter_user) }
  let(:fetcher) { TwitterUserFetcher.new(twitter_user, client: nil, login_user: nil) }

  describe '#reject_relation_names' do
    subject { fetcher.send(:reject_relation_names) }

    context 'SearchLimitation.limited? == true' do
      before { allow(SearchLimitation).to receive(:limited?).with(any_args).and_return(true) }

      it { is_expected.to match(%i(friend_ids follower_ids)) }
    end
  end
end