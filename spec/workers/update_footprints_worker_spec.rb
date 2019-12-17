require 'rails_helper'

RSpec.describe UpdateFootprintsWorker do
  describe '#unique_key' do
    let(:worker) { described_class.new }
    it do
      expect(worker.unique_key(nil, {user_id: 1})).to eq(1)
      expect(worker.unique_key(nil, {'user_id' => 1})).to eq(1)
    end
  end

  describe '#perform' do
    let(:user) { create(:user, first_access_at: nil, last_access_at: nil) }
    let(:log) { create(:search_log, user: user) }
    let(:worker) { described_class.new }
    subject { worker.perform(log.id) }

    before do
      allow(SearchLog).to receive(:find).with(log.id).and_return(log)
    end

    it do
      expect(worker).to receive(:assign_user_access_at).with(user, log)
      expect(worker).to receive(:assign_user_search_at).with(user, log)
      subject
    end
  end

  describe '#assign_user_access_at' do
    let(:user) { create(:user, first_access_at: nil, last_access_at: nil) }
    let(:log) { create(:search_log, created_at: Time.zone.now) }
    subject { described_class.new.send(:assign_user_access_at, user, log) }

    context '#first_access_at' do
      it do
        subject
        expect(user.first_access_at).to eq(log.created_at)
      end
    end

    context '#last_access_at' do
      it do
        subject
        expect(user.last_access_at).to eq(log.created_at)
      end
    end
  end

  describe '#assign_user_search_at' do

  end
end
