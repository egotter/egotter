require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Profile do
  let(:twitter_user) { create(:twitter_user) }

  describe '#account_created_at' do
    subject { twitter_user.account_created_at }
    it do
      profile_created_at = twitter_user.send(:profile)[:created_at]
      time = ActiveSupport::TimeZone['Asia/Tokyo'].parse(profile_created_at)
      is_expected.to be_within(3.seconds).of(time)
    end
  end

  describe '#profile_not_found?' do
    subject { twitter_user.profile_not_found? }
    it do
      is_expected.to be_falsey
    end
  end

  describe '#profile' do
    subject { twitter_user.send(:profile) }
    before { allow(twitter_user).to receive(:fetch_profile).and_return(dummy: true) }
    it { is_expected.to eq(Hashie::Mash.new(dummy: true)) }
  end

  describe '#fetch_profile' do
    subject { twitter_user.send(:fetch_profile) }

    context 'Fetch profile from EFS' do
      before do
        allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(profile: {from: 'efs'})
      end

      it { is_expected.to eq(from: 'efs') }
    end

    context 'Fetch profile from S3' do
      before do
        allow(Efs::TwitterUser).to receive(:find_by).with(twitter_user.id).and_return(profile: {})
        allow(S3::Profile).to receive(:find_by).with(twitter_user_id: twitter_user.id).and_return(user_info: '{"from":"s3"}')
      end

      it { is_expected.to eq({from: 's3'}.to_json) }
    end
  end
end
