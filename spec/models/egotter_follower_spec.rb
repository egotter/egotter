require 'rails_helper'

RSpec.describe EgotterFollower, type: :model do
  describe '.update_all_uids' do
    let(:uids) { [1, 2, 3, 5, 6] }
    let(:persisted_uids) { [1, 2, 3, 4, 5] }
    let(:importable_uids) { [6] }
    let(:deletable_uids) { [4] }
    subject { described_class.update_all_uids }
    before { persisted_uids.each { |uid| create(:egotter_follower, uid: uid) } }
    it do
      expect(described_class.pluck(:uid)).to eq(persisted_uids)
      expect(described_class).to receive(:collect_uids).and_return(uids)
      expect(described_class).to receive(:filter_necessary_uids).with(uids).and_call_original
      expect(described_class).to receive(:import_uids).with(importable_uids).and_call_original
      expect(described_class).to receive(:filter_unnecessary_uids).with(uids).and_call_original
      expect(described_class).to receive(:delete_uids).with(deletable_uids).and_call_original
      subject
      expect(described_class.pluck(:uid)).to eq(uids)
    end
  end

  describe '.collect_uids' do
    subject { described_class.collect_uids }
    before { allow(described_class).to receive(:collect_with_max_id).and_return('response') }
    it { is_expected.to eq('response') }
  end

  describe '.collect_with_max_id' do
    let(:ids) { [1, 2, 3] }
    subject do
      described_class.collect_with_max_id do
        double('Response', attrs: {ids: ids, next_cursor: 0})
      end
    end
    it { is_expected.to eq(ids) }
  end

  describe '.import_uids' do
    subject { described_class.import_uids([1, 2, 3]) }
    before { create(:egotter_follower, uid: 2) }
    it { expect { subject }.to change { described_class.all.size }.by(2) }
  end

  describe '.filter_unnecessary_uids' do
    subject { described_class.filter_unnecessary_uids([2, 3]) }
    before { create(:egotter_follower, uid: 1) }
    it { is_expected.to eq([1]) }
  end

  describe '.delete_uids' do
    subject { described_class.delete_uids([1, 2]) }
    before { create(:egotter_follower, uid: 1) }
    it { expect { subject }.to change { described_class.all.size }.by(-1) }
  end
end
