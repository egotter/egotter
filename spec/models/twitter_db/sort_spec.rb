require 'rails_helper'

RSpec.describe TwitterDB::Sort, type: :model do
  describe '#apply' do
    let(:query) { TwitterDB::User }
    let(:uids) { [1, 2, 3] }
    let(:instance) { described_class.new(value) }
    subject { instance.apply(query, uids) }
    before do
      [
          create(:twitter_db_user, uid: 1, friends_count: 1, followers_count: 2, statuses_count: 2),
          create(:twitter_db_user, uid: 2, friends_count: 3, followers_count: 1, statuses_count: 3),
          create(:twitter_db_user, uid: 3, friends_count: 2, followers_count: 3, statuses_count: 1),
      ]
    end

    context "desc is passed" do
      let(:value) { 'desc' }
      it { is_expected.to eq([1, 2, 3]) }
    end

    context "asc is passed" do
      let(:value) { 'asc' }
      it { is_expected.to eq([3, 2, 1]) }
    end

    context "friends_desc is passed" do
      let(:value) { 'friends_desc' }
      it { is_expected.to eq([2, 3, 1]) }
    end

    context "friends_asc is passed" do
      let(:value) { 'friends_asc' }
      it { is_expected.to eq([1, 3, 2]) }
    end

    context "followers_desc is passed" do
      let(:value) { 'followers_desc' }
      it { is_expected.to eq([3, 1, 2]) }
    end

    context "followers_asc is passed" do
      let(:value) { 'followers_asc' }
      it { is_expected.to eq([2, 1, 3]) }
    end

    context "statuses_desc is passed" do
      let(:value) { 'statuses_desc' }
      it { is_expected.to eq([2, 1, 3]) }
    end

    context "statuses_asc is passed" do
      let(:value) { 'statuses_asc' }
      it { is_expected.to eq([3, 1, 2]) }
    end

    context 'the size of uids is greater than the threshold' do
      let(:value) { 'friends_desc' }
      let(:cache) { TwitterDB::SortCache.instance }
      before { instance.threshold(1) }

      context 'cache exists' do
        before { allow(cache).to receive(:exists?).with(value, uids).and_return(true) }
        it do
          expect(cache).to receive(:read).with(value, uids).and_return('result')
          is_expected.to eq('result')
        end
      end

      context 'cache does not exist' do
        before { allow(cache).to receive(:exists?).with(value, uids).and_return(false) }
        it do
          expect(CreateTwitterDBSortCacheWorker).to receive(:perform_async).with(value, uids).and_return('jid')
          expect { subject }.to raise_error(TwitterDB::Sort::CreatingCache)
        end
      end
    end
  end

  describe '#work_in_threads' do
    let(:instance) { described_class.new(nil) }
    let(:queries) { 1000.times.map { |n| [n] } }
    subject { instance.work_in_threads(queries, 10) }
    it { is_expected.to eq(queries.flatten) }

    context 'TimeoutError is raised' do
      let(:task) { double('task') }
      let(:queries) { 10.times.map { task } }
      before do
        instance.instance_variable_set(:@start_time, Time.zone.now)
        allow(instance).to receive(:timeout?).and_return(true)
        allow(task).to receive(:to_a).and_raise('Not allowed to perform any tasks')
      end
      it { expect { subject }.to raise_error(described_class::SafeTimeout) }
    end
  end

  describe '#work_direct' do
    let(:instance) { described_class.new(nil) }
    let(:queries) { 1000.times.map { |n| [n] } }
    subject { instance.work_direct(queries) }
    it { is_expected.to eq(queries.flatten) }
  end
end
