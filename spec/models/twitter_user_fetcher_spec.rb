require 'rails_helper'

RSpec.describe TwitterUserFetcher do
  let(:twitter_user) { build(:twitter_user) }
  let(:client) { double('Client') }
  let(:instance) { described_class.new(twitter_user, login_user: nil, context: nil) }

  before { allow(Bot).to receive(:api_client).and_return(client) }

  describe '#fetch' do
    let(:signatures) do
      [
          {method: :friend_ids, args: [123]},
          {method: :follower_ids, args: [456]},
      ]
    end
    subject { instance.fetch }
    before do
      allow(instance).to receive(:reject_relation_names).and_return('reject_names')
      allow(instance).to receive(:fetch_signatures).and_return(signatures)
    end
    it do
      expect(client).to receive(:friend_ids).with(123).and_return('r1')
      expect(client).to receive(:follower_ids).with(456).and_return('r2')
      is_expected.to eq(friend_ids: 'r1', follower_ids: 'r2')
      expect(instance.api_name).to eq(:follower_ids)
    end
  end

  describe '#reject_relation_names' do
    subject { instance.send(:reject_relation_names) }

    context 'SearchLimitation.limited? == true' do
      before { allow(SearchLimitation).to receive(:limited?).with(any_args).and_return(true) }

      it { is_expected.to match(%i(friend_ids follower_ids)) }
    end
  end
end
