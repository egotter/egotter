require 'rails_helper'

RSpec.describe UpdateEgotterFollowersWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }
    it do
      expect(worker).to receive(:fetch_follower_uids).with(User::EGOTTER_UID).and_return('uids')
      expect(worker).to receive(:build_followers).with('uids').and_return('users')
      expect(worker).to receive(:import_followers).with('users')
      subject
    end
  end

  describe '#fetch_follower_uids' do

  end

  describe '#build_followers' do

  end

  describe '#import_followers' do
    subject { worker.import_followers('users') }
    it do
      expect(EgotterFollower).to receive(:import).with('users', on_duplicate_key_update: %i(uid), validate: false, timestamps: false)
      subject
    end
  end
end
