require 'rails_helper'

RSpec.describe TwitterUserQueryMethods do
  let(:uid) { 1 }
  let(:screen_name) { 'sn' }
  let(:record1) { build(:twitter_user, with_relations: false, uid: uid, screen_name: screen_name, created_at: 1.minute.ago) }
  let(:record2) { build(:twitter_user, with_relations: false, uid: uid, screen_name: screen_name, created_at: 1.second.ago) }
  let(:record3) { build(:twitter_user, with_relations: false, uid: uid, screen_name: screen_name) }

  before do
    record1.save!(validate: false)
    record2.save!(validate: false)
    record3.save!(validate: false)
  end

  it { expect(described_class::DEFAULT_TIMESTAMP_DELAY).to eq(3.seconds) }

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

  describe '#unfriends_target' do
    let(:twitter_user) { create(:twitter_user) }
    subject { twitter_user.unfriends_target }
    it do
      expect(TwitterUser).to receive_message_chain(:select, :creation_completed, :where, :where, :order, :limit, :reverse).
          with(:id, :uid, :screen_name, :created_at).with(no_args).with(uid: twitter_user.uid).
          with('created_at <= ?', twitter_user.created_at).with(created_at: :desc).with(50).with(no_args)
      subject
    end
  end
end
