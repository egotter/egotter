require 'rails_helper'

RSpec.describe BlockingRelationship, type: :model do
  describe '.update_all_blocks' do
    let(:user) { create(:user) }
    let(:uids) { [1, 2, 3, 5, 6] }
    let(:persisted_uids) { [1, 2, 3, 4, 5] }
    let(:importable_uids) { [6] }
    let(:deletable_uids) { [4] }
    subject { described_class.update_all_blocks(user) }
    before { persisted_uids.each { |uid| create(:blocking_relationship, from_uid: user.uid, to_uid: uid) } }
    it do
      expect(described_class.pluck(:to_uid)).to eq(persisted_uids)
      expect(described_class).to receive(:collect_uids).with(user.id).and_return(uids)
      expect(described_class).to receive(:filter_additional_blocks).with(user.uid, uids).and_call_original
      expect(described_class).to receive(:import_blocks).with(user.uid, importable_uids).and_call_original
      expect(described_class).to receive(:filter_deletable_blocks).with(user.uid, uids).and_call_original
      expect(described_class).to receive(:delete_blocks).with(user.uid, deletable_uids).and_call_original
      subject
      expect(described_class.pluck(:to_uid)).to eq(uids)
    end
  end

  describe '.import_blocks' do
    let(:from_uid) { 1 }
    let(:to_uids) { (2..1500).to_a }
    subject { described_class.import_blocks(from_uid, to_uids) }
    it do
      expect { subject }.to change { described_class.all.size }.by(1499)
      subject
      expect(described_class.pluck(:from_uid, :to_uid)).to eq(to_uids.map { |to_uid| [from_uid, to_uid] })
    end
  end

  describe '.filter_additional_blocks' do
    let(:from_uid) { 1 }
    let(:to_uids) { [2, 3, 4] }
    subject { described_class.filter_additional_blocks(from_uid, to_uids) }
    before { create(:blocking_relationship, from_uid: from_uid, to_uid: 3) }
    it { is_expected.to eq([2, 4]) }
  end

  describe '.filter_deletable_blocks' do
    let(:from_uid) { 1 }
    let(:to_uids) { [2, 3, 4] }
    subject { described_class.filter_deletable_blocks(from_uid, to_uids) }
    before { create(:blocking_relationship, from_uid: from_uid, to_uid: 5) }
    it { is_expected.to eq([5]) }
  end

  describe '.delete_blocks' do
    let(:from_uid) { 1 }
    let(:to_uids) { [2, 3, 4] }
    subject { described_class.delete_blocks(from_uid, to_uids) }
    before { create(:blocking_relationship, from_uid: from_uid, to_uid: 3) }
    it { expect { subject }.to change { described_class.all.size }.by(-1) }
  end

  describe '.import_from' do
    subject { described_class.import_from(1, [2, 3]) }
    it { expect { subject }.to change { described_class.all.size }.by(2) }
  end

  describe '.collect_uids' do
    let(:user) { create(:user) }
    let(:client) { double('client') }
    let(:response) { double('response', attrs: {ids: [1, 2, 2, 3], next_cursor: 0}) }
    subject { described_class.collect_uids(user.id) }
    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive_message_chain(:api_client, :twitter).and_return(client)
      allow(client).to receive(:blocked_ids).with(anything).and_return(response)
    end
    it { is_expected.to eq([1, 2, 3]) }
  end
end
