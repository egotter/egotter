require 'rails_helper'

RSpec.describe Concerns::TwitterUser::QueryMethods do
  let(:uid) { 1 }
  let(:screen_name) { 'sn' }
  let(:record1) { build(:twitter_user, uid: uid, screen_name: screen_name, created_at: 5.seconds.ago) }
  let(:record2) { build(:twitter_user, uid: uid, screen_name: screen_name, created_at: 2.seconds.ago) }
  let(:record3) { build(:twitter_user, uid: uid, screen_name: screen_name, created_at: 1.second.ago) }

  before do
    record1.save!(validate: false)
    record2.save!(validate: false)
    record3.save!(validate: false)
  end

  describe '.latest_by' do
    context 'With uid' do
      subject { TwitterUser.latest_by(uid: uid) }
      it { is_expected.to satisfy { |r| r.id == record3.id } }
    end

    context 'With screen_name' do
      subject { TwitterUser.latest_by(screen_name: screen_name) }
      it { is_expected.to satisfy { |r| r.id == record3.id } }
    end
  end

  describe '.with_delay' do
    subject { TwitterUser.with_delay }
    it { is_expected.to satisfy { |q| q.order(created_at: :desc).first.id == record1.id } }
  end
end
