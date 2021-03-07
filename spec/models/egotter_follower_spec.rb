require 'rails_helper'

RSpec.describe EgotterFollower, type: :model do
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
